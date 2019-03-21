#! /usr/bin/env perl
use utf8;
package FamilyAPI;
use strict;
use warnings;

use WebLog;
use FamilyDB;
use DateTime;

# 错误码设计
my $MESSAGE_REF = {
	ERR_SUCCESS => '0. 成功',
	ERR_SYSTEM => '-1. 系统错误',
	ERR_SYSNO_API => '-2. 系统错误，缺少接口，请检查接口名',
	ERR_ARGUMENT => '1. 参数错误',
	ERR_ARGNO_API => '2. 参数错误，缺少接口名字',
	ERR_ARGNO_DATA => '3. 参数错误，缺少接口数据',
	ERR_ARGNO_ID => '5. 参数错误，缺少ID',
	ERR_ARGNO_NAME => '6. 参数错误，缺少人名',
	ERR_ARGNO_SEX => '7. 参数错误，缺少性别',
	ERR_ARGNO_RELATE => '8. 参数错误，缺少代际关系',
	ERR_DBI_FAILED => '10. 数据库操作失败',
	ERR_NAME_DUPED => '11. 数据库中存在重名，建议改用唯一ID',
	ERR_NAME_LACKED => '12. 数据库中不存在该人名，请检查',
	ERR_PARENT_LACKED => '13. 缺少父母关系',
	ERR_PARENT_DISMATCH => '14. 父母辈份不匹配',
	ERR_MEMBER_LACKED => '15. 不存在成员ID',
	ERR_ARGNO_TEXT => '16. 参数错误，缺少简介文本',
	ERR_LOGIN_PASS_WRONG => '17. 登陆密码不对',
	ERR_OPERA_PASS_WRONG => '18. 操作密码不对',
	ERR_ARGNO_SESS => '19. 参数错误，缺少会话信息',
	ERR_OPERA_TOKEN_WRONG => '20. 会话不匹配',
	ERR_ONLY_FATHER => '21. 只记录父系后代',
	ERR_ALREADY_ROOT => '22. 已经存在始祖了',
};

sub error_msg
{
	my ($error) = @_;
	return $MESSAGE_REF->{$error} || "未知错误";
}

# 响应函数配置
# 响应函数要求返回两个值 ($error, $res_data)，错误码及实际数据
# 能接收两个参数 ($db, $req_data) ，数据库对象、请求数据
my $HANDLER = {
	query => \& handle_query,
	create => \& handle_create,
	modify => \& handle_modify,
	remove => \& handle_remove,
	member_relations => \& handle_member_relations,

	query_brief => \& handle_query_brief,
	create_brief => \& handle_create_brief,
	modify_brief => \& handle_modify_brief,
	remove_brief => \& handle_remove_brief,

	login => \&handle_login,
	modify_passwd => \&handle_modify_passwd,
};

# 请求入口，分发响应函数
# req = {api => '接口名', data => {实际请求数据}, sess=>{会话及操作密码}}
# 修改数据库操作将验证 sess
sub handle_request
{
	my ($jreq) = @_;

	my $api = $jreq->{api}
		or return response('ERR_ARGNO_API');
	my $req_data = $jreq->{data}
		or return response('ERR_ARGNO_DATA');
	my $handler = $HANDLER->{$api}
		or return response('ERR_SYSNO_API');

	my $db = FamilyDB->new();
	if ($db->{error}) {
		return response('ERR_DBI_FAILED', $db->{error});
	}

	if ($api =~ /create|modify|remove/i && !$jreq->{admin}) {
		my $sess = $jreq->{sess} or return response('ERR_ARGNO_SESS');
		my $error = check_session($db, $sess);
		if ($error) {
			return response($error);
		}
	}

	my ($error, $res_data) = $handler->($db, $req_data);
	$db->Disconnect();

	return response($error, $res_data);
}

# 将派发函数返回的两个参数，发回客户端
# 只有 $error 为假时，$data 才有效，否则当作错误信息附加在 errmsg
# 不出错时，返回空 error 码与　data 数据字段
sub response
{
	my ($error, $data) = @_;

	my $res = { error => $error};
	if ($error) {
		$res->{errmsg} = error_msg($error);
		if ($data && !ref($data)) {
			$res->{errmsg} .= ": " . $data;
		}
		wlog("RES error: $res->{errmsg}");
		return $res;
	}

	$res->{data} = $data if $data;

	return $res;
}

=sub handle_query()
  _query: 查询成员
 
请求：
  req = {
    all => 全部选择，忽略其他条件
    page => 第几页
    perpage => 每页几条记录
    filter => { 筛选条件
    id => 单个 id 或 [多个 id 列表]
    name => 姓名
    sex => 性别 1/2
    level => 代际
    father => 父亲
	sibold =>
	partner =>
    age => [年龄区间，两个数字]
    }
    fields => [需要的列，或默认]
  }
 
响应：
  res = {
    total => 总记录条数
    page => 第几页
    perpage => 每页记录数
    records => [记录列表]
      每个列表元素是 {请求指定的列}
  }
 
返回：
  ($error, $res)
=cut
sub handle_query
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	# fields 直接取请求参数，允许 undef
	my $fields = $jreq->{fields};

	# 计算 limit 分页上下限
	my $page = 0 + $jreq->{page} || 1;
	my $perpage = 0 + $jreq->{perpage} || 100;
	my $lb = ($page-1) * $perpage;
	my $ub = ($page) * $perpage;
	my $limit = "$lb,$perpage";

	# 默认不选姓名为 '0' 与旁系
	my $where = {};
	if (!$jreq->{filter} || !$jreq->{filter}->{id}) {
		$where = {F_name => {'!=' => '0'}};
	}
	if (!$jreq->{all} && $jreq->{filter}) {
		my $filter = $jreq->{filter};
		$where->{F_id} = $filter->{id} if $filter->{id};
		$where->{F_name} = $filter->{name} if $filter->{name};
		$where->{F_sex} = $filter->{sex} if $filter->{sex};
		$where->{F_level} = $filter->{level} if $filter->{level};
		$where->{F_father} = $filter->{father} if $filter->{father};
		$where->{F_sibold} = $filter->{sibold} if $filter->{sibold};
		$where->{F_partner} = $filter->{partner} if $filter->{partner};

		# 模糊查询 name
		if ($filter->{name} && $filter->{name} =~ /%/) {
			$where->{F_name} = {-like => $filter->{name}};
		}

		if ($filter->{birthday}) {
			my $birthday = $filter->{birthday};
			if (ref($birthday) eq 'ARRAY') {
				$where->{F_birthday} = {-between => $birthday};
			}
			elsif (!ref($birthday)) {
				$where->{F_birthday} = {'>=' => $birthday};
			}
		}

		if ($filter->{deathday}) {
			my $deathday = $filter->{deathday};
			if (ref($deathday) eq 'ARRAY') {
				$where->{F_deathday} = {-between => $deathday};
			}
			elsif (!ref($deathday)) {
				$where->{F_deathday} = {'<=' => $deathday};
			}
		}

		if ($filter->{age}) {
			my $age = $filter->{age};
			if (ref($age) eq 'ARRAY') {
				my $birth_from = DateTime->now->add(years => -$age->[1]);
				my $birth_to = DateTime->now->add(years => -$age->[0]);
				$where->{F_birthday} = {-between => [$birth_from, $birth_to]};
			}
			elsif (!ref($age)) {
				my $birth_from = DateTime->now->add(years => -$age->[0]);
				$where->{F_bithathday} = {'>=' => $birth_from};
			}
		}
	}

	# 默认按代际排序
	my $order = ['F_level', 'F_id'];
	my $records = $db->Query($fields, $where, $limit, $order);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	$jres->{records} = $records;
	$jres->{page} = $page;
	$jres->{perpage} = $perpage;
	my $total = scalar(@{$records});
	if ($page <= 1 && $total >= $perpage) {
		$total= $db->Count($where);
	}
	$jres->{total} = $total;

	return ($error, $jres);
}

=sub handle_create()
  _create: 增加成员
 
  请求：
  req = {
    id => 写定编号，否则自增
    name => 姓名
    sex => 性别
    father_name => 父亲姓名，通过姓名查 id，有重名或查不到时报错
    father_id => 直接指定 id ，优先级比姓名高
	partner => 提供配偶姓名，同时为配偶增加一条记录
	sibold => 兄弟长序
    birthday => 生日
    deathday => 忌日
    // desc => 简介文字
	requery => 重新查询插入的数据
	root => 是否先祖，插入先祖时不检查父亲，level 设 1
  }
 
  响应：
  res = {
    created => 1
    id => 新插入成员的 id
	mine => {} 重查的记录
  }
=cut
sub handle_create
{
	wlog('headle this ...');
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	my $mine_name = $jreq->{name}
		or return ('ERR_ARGNO_NAME');
	my $mine_sex = $jreq->{sex} // 0;
	if ($mine_sex != 1 && $mine_sex != 2) {
		return ('ERR_ARGNO_SEX');
	}

	if (!$jreq->{root}) {
		$error = check_parent($db, $jreq);
		return ($error) if $error;
	}
	else {
		my $has_root = $db->Count({F_level => 1});
		if ($has_root) {
			return ('ERR_ALREADY_ROOT');
		}
		$jreq->{level} = 1;
		delete $jreq->{father};
	}

	my $fieldvals = {};
	$fieldvals->{F_name} = $mine_name;
	$fieldvals->{F_sex} = $mine_sex;

	$fieldvals->{F_level} = $jreq->{level};
	unless ($fieldvals->{F_level}) {
		$error = 'ERR_ARGNO_RELATE';
		return ($error, $jres);
	}

	$fieldvals->{F_id} = $jreq->{id} if $jreq->{id};
	$fieldvals->{F_father} = $jreq->{father} if $jreq->{father};
	$fieldvals->{F_partner} = $jreq->{partner} if $jreq->{partner};
	$fieldvals->{F_sibold} = $jreq->{sibold} if $jreq->{sibold};
	$fieldvals->{F_birthday} = $jreq->{birthday} if $jreq->{birthday};
	$fieldvals->{F_deathday} = $jreq->{deathday} if $jreq->{deathday};

	my $now_time = now_time_str();
	$fieldvals->{F_create_time} = $now_time;
	$fieldvals->{F_update_time} = $now_time;

	my $ret = $db->Create($fieldvals);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to insert just one row: $ret");
	}

	$jres->{created} = $ret;
	if ($jreq->{id}) {
		$jres->{id} = $jreq->{id};
	}
	else {
		$jres->{id} = $db->LastInsertID();
	}

	# 重查
	if ($jreq->{requery}) {
		my $jqry = {filter => { id => $jres->{id}}};
		my ($qry_err, $qry_res) = handle_query($db, $jqry);
		if ($qry_err) {
			$error = $qry_err;
		}
		elsif ($qry_res->{records}) {
			$jres->{mine} = $qry_res->{records}->[0]; 
		}
	}

	return ($error, $jres);
}

=sub handle_modify()
  _modify: 修改成员资料
  请求：
  req = {
    id => 只支持用 id 标定一行修改
    其他参数与 create 相同
  }
  响应：
  res = {
    modified => 1
	id => 新插入成员的 id
	mine => {} 重查的记录
  }
=cut
sub handle_modify
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	my $mine_id = $jreq->{id}
		or return('ERR_ARGNO_ID');

	# 修改时不必要求父母参数
	check_parent($db, $jreq);

	my $fieldvals = {};
	$fieldvals->{F_name} = $jreq->{name} if defined($jreq->{name});
	if (defined($jreq->{sex}) && ($jreq->{sex} == 1 || $jreq->{sex} == 2)) {
		$fieldvals->{F_sex} = $jreq->{sex};
	}
	$fieldvals->{F_father} = $jreq->{father} if $jreq->{father};
	$fieldvals->{F_partner} = $jreq->{partner} if $jreq->{partner};
	$fieldvals->{F_sibold} = $jreq->{sibold} if $jreq->{sibold};
	$fieldvals->{F_birthday} = $jreq->{birthday} if $jreq->{birthday};
	$fieldvals->{F_deathday} = $jreq->{deathday} if $jreq->{deathday};

	my $now_time = now_time_str();
	$fieldvals->{F_update_time} = $now_time;

	my $ret = $db->Modify($fieldvals, { F_id => $mine_id});
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to modify just one row");
		$error = 'ERR_DBI_FAILED';
	}

	$jres->{modified} = $ret;
	$jres->{id} = $jreq->{id};

	if ($jreq->{requery}) {
		my $jqry = {filter => { id => $jres->{id}}};
		my ($qry_err, $qry_res) = handle_query($db, $jqry);
		if ($qry_err) {
			$error = $qry_err;
		}
		elsif ($qry_res->{records}) {
			$jres->{mine} = $qry_res->{records}->[0];
		}
	}

	return ($error, $jres);
}

=sub handle_remove()
 _remove 删除一个成员
 请求：
 req = {
   id => 只支持用 id 标定一行修改
 }
 响应：
 res = {
    removed => 1
 }
=cut
sub handle_remove
{
	my ($db, $jreq) = @_;
	my $mine_id = $jreq->{id} or return('ERR_ARGNO_ID');

	my $where = {F_id => $mine_id};
	my $ret = $db->Remove($where);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
	return ('ERR_DBI_FAILED', "Expect to delete just one row") if ($ret != 1);

	return (0, {removed => $ret});
}

# 检查父亲关系，返回错误码
# 根据父亲 id 或姓名，检查存在唯一性，并确定后代辈份
sub check_parent
{
	my ($db, $jreq) = @_;

	my $where = {};
	if ($jreq->{father_id}) {
		$where->{F_id} = $jreq->{father_id};
	}
	elsif ($jreq->{father_name}) {
		$where->{F_name} = $jreq->{father_name};

	}
	else {
		return 'ERR_PARENT_LACKED';
	}

	my $records = $db->Query(['F_id, F_level', 'F_sex'], {F_name => $jreq->{father_name}});
	if ((scalar @$records) < 1) {
		return 'ERR_NAME_LACKED';
	}
	elsif ((scalar @$records) > 1) {
		return 'ERR_NAME_DUPED';
	}

	my $sex = $records->[0]->{F_sex};
	if ($sex != 1) {
		return 'ERR_ONLY_FATHER';
	}

	my $father_level = $records->[0]->{F_level};
	if (!$father_level) {
		return 'ERR_PARENT_LACKED';
	}

	$jreq->{father} = $records->[0]->{F_id};
	$jreq->{level} = $father_level + 1;

	return 0;
}

sub now_time_str
{
	my $now_obj = DateTime->now;
	my $now_time = $now_obj->ymd . ' ' . $now_obj->hms;
	return $now_time;
}

=sub handle_member_relations
req = {
  id => 待查成员 id
  mine => 1/0 包含自己
  parents => -1/1, 2 查多少代祖辈
  children => 1/0 包含子女
  sibling => 1/0 包含兄弟
}
res = {
  id => 原样返回
  （其他参数同名返回记录数组）
}
=cut
sub handle_member_relations
{
	my ($db, $jreq) = @_;
	
	my $error = 0;
	my $jres = {};

	my $id = $jreq->{id}
		or return ('ERR_ARGNO_ID');

	# 先查自己
	my $filter = {id => $id};
	my $qry_data = {filter => $filter};
	my ($qry_err, $qry_res) = handle_query($db, $qry_data);
	if ($qry_err || !$qry_res->{records}) {
		return ('ERR_MEMBER_LACKED');
	}

	my $row_mine = $qry_res->{records}->[0];

	$jres->{id} = $id;
	$jres->{mine} = $qry_res->{records} if $jreq->{mine};

	# 查孩子
	if ($jreq->{children}) {
		$filter = {father => $id};
		($qry_err, $qry_res) = handle_query($db, {filter => $filter});
		if (!$qry_err && $qry_res->{records}) {
			$jres->{children} = $qry_res->{records};
		}
	}

	# 查先祖
	if ($jreq->{parents} && $row_mine->{F_level} > 1) {
		my $req_level = $jreq->{parents};
		my $max_level = $row_mine->{F_level} - 1;
		if ($req_level < 0) {
			$req_level = $max_level;
		}

		my $roots = [];
		my $row = $row_mine;
		for (my $level = 0; $level < $req_level && $level < $max_level; $level++) {
			wlog("query parent from id: $row->{F_id}; level $row->{F_level}");
			my $parent = select_parent($db, $row);
			last unless $parent;
			push(@$roots, $parent);
			$row = $parent;
		}

		$jres->{parents} = $roots;
	}

	# 查兄弟
	if ($jreq->{sibling} && $row_mine->{F_level} > 1) {
		my $parent = $jres->{parents}->[0];
		if (!$parent) {
			wlog('没查到父母，无法查兄弟');
		}
		else {
			$filter = {father => $parent->{F_id}};
			# 排除自己
			$filter->{id} = {'!=' => $row_mine->{F_id}};
			($qry_err, $qry_res) = handle_query($db, {filter => $filter});
			if (!$qry_err && $qry_res->{records}) {
				$jres->{sibling} = $qry_res->{records};
			}
		}
	}

	return ($error, $jres);
}

# 根据自己这行，查找直系父亲那行，失败时返回 undef
sub select_parent
{
	my ($db, $row_mine) = @_;
	
	if ($row_mine <= 1) {
		wlog('已到顶层祖先，无法再追查父母');
		return undef;
	}

	if ($row_mine->{F_father}) {
		my $parent = query_single($db, $row_mine->{F_father});
		return $parent if ($parent && $parent->{F_level} > 0);
	}

	return undef;
}

# 按 id 查询单行，直接返回记录 hashref ，不存在时返回 undef
sub query_single
{
	my ($db, $id) = @_;
	my $filter = {id => $id};
	my ($qry_err, $qry_res) = handle_query($db, {filter => $filter});
	if ($qry_err || !$qry_res->{records}) {
		return undef;
	}
	return $qry_res->{records}->[0];
}

=head1 brief table operate
=cut

=markdown handle_query_brief()
	查询简介
	req = { id }
	res = { F_id, F_text }
=cut
sub handle_query_brief
{
	my ($db, $jreq) = @_;
	my $id = $jreq->{id} or return ('ERR_ARGNO_ID');

	my $text = $db->QueryBrief($id);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	return (0, {F_id => $id, F_text => $text});
}

=markdown handle_create_brief()
	创建简介
	req = { id, text }
	res = { F_id, affected }
=cut
sub handle_create_brief
{
	my ($db, $jreq) = @_;
	my $id = $jreq->{id} or return ('ERR_ARGNO_ID');
	return ('ERR_ARGNO_TEXT') if !$jreq->{text};
	my $text = $jreq->{text};

	my $affected = $db->CreateBrief($id, $text);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	return (0, {F_id => $id, affected => $affected});
}

=markdown handle_modify_brief()
	修改简介
	req = { id, text, create }
	如果指定 create 则在原无简介记录时也尝试新建
	res = { F_id, affected }
=cut
sub handle_modify_brief
{
	my ($db, $jreq) = @_;
	my $id = $jreq->{id} or return ('ERR_ARGNO_ID');
	return ('ERR_ARGNO_TEXT') if !defined($jreq->{text});
	my $text = $jreq->{text};

	my $affected = $jreq->{create}
		? $db->ReplaceBrief($id, $text)
		: $db->ModifyBrief($id, $text);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	return (0, {F_id => $id, affected => $affected});
}

=markdown handle_remove_brief()
	删除简介
	req = { id }
	res = { F_id, affected }
=cut
sub handle_remove_brief
{
	my ($db, $jreq) = @_;
	my $id = $jreq->{id} or return ('ERR_ARGNO_ID');

	my $affected = $db->RemoveBrief($id);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	return (0, {F_id => $id, affected => $affected});
}

=head1 passwd table operate
=cut

# 返回 32 位随机 token ，由大写 A-Z 组成
my @LETTER = ('A' .. 'Z');
sub randToken
{
	return join '', map{$LETTER[int rand @LETTER]} (1..32);
}

=markdown handel_login()
  登陆
  req = {id, name, key}
  res = {id, token, mine}
  可按 id 或 name 登陆，但返回 id ，同时返回整行数据
  初始密码与 id 一样
=cut
sub handle_login
{
	my ($db, $jreq) = @_;

	my $where = {};
	$where->{F_id} = $jreq->{id} if $jreq->{id};
	$where->{F_name} = $jreq->{name} if $jreq->{name};

	# 最多查两行
	my $records = $db->Query(undef, $where, 2);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if (scalar @$records > 1) {
		return ('ERR_NAME_DUPED');
	}
	if (scalar @$records < 1) {
		return ('ERR_MEMBER_LACKED');
	}

	my $mine = $records->[0];
	my $id = $mine->{F_id};

	# 验证密码
	my $key = $jreq->{key};
	my $token = '';

	my @fields = qw(F_id F_login_key F_token);
	my $record = $db->QueryPasswd($id, \@fields);

	# 取数据库保存的密码比对，初始假设为 id 并保存
	my $key_db;
	if ($record) {
		$key_db = $record->{F_login_key};
		$token = $record->{F_token};
	}
	else {
		$key_db = $id;
	}
	if ($key_db && $key ne $key_db) {
		return ('ERR_LOGIN_PASS_WRONG');
	}

	if ($token) {
		$token++;
		# 极端情况：字母位数增加，超过 mysql 字段限，能否安全截断？
	}
	else {
		$token = randToken();
	}

	my $ret;
	my $now_time = now_time_str();
	my $fieldvals = {F_token => $token, F_update_time => $now_time, F_last_login => $now_time};
	# 无密码记录时插入，或修改
	if (!$record) {
		wlog('create passwd for firstly login');
		$fieldvals->{F_login_key} = $id;
		$fieldvals->{F_opera_key} = $id;
		$ret = $db->CreatePasswd($id, $fieldvals);
	}
	else {
		wlog('update token');
		$ret = $db->ModifyPasswd($id, $fieldvals);
	}

	if (!$ret) {
		wlog('修改密码表的 token 失败');
	}

	return (0, {id => $id, token => $token, mine => $mine});
}

=markdown handle_modify_passwd()
  修改密码
  req = { id, keytype, oldkey, newkey }
    keytype 取值：loginkey 或 operakey
  res = { id, affected }
    原样返回 id 及影响行数
=cut
sub handle_modify_passwd
{
	my ($db, $jreq) = @_;
	my $id = $jreq->{id} || return ('ERR_ARGNO_ID');
	my $type = $jreq->{keytype} || return ('ERR_ARGUMENT', '缺少密码类型');
	if (!$jreq->{oldkey} || !$jreq->{newkey}) {
		return ('ERR_ARGUMENT', '不能修改空密码');
	}

	my $now_time = now_time_str();
	my $fieldvals = {F_update_time => $now_time};
	my $oldkey_db;
	my $ret;
	if ($type eq 'loginkey') {
		$fieldvals->{F_login_key} = $jreq->{newkey};
		my $record = $db->QueryPasswd($id, ['F_login_key']);
		if ($record) {
			$oldkey_db = $record->{F_login_key};
			if ($oldkey_db && $oldkey_db != $jreq->{oldkey}) {
				return ('ERR_LOGIN_PASS_WRONG');
			}
			$ret = $db->ModifyPasswd($id, $fieldvals);
		}
		else {
			$ret = $db->CreatePasswd($id, $fieldvals);
		}
	}
	elsif ($type eq 'operakey') {
		$fieldvals->{F_opera_key} = $jreq->{newkey};
		my $record = $db->QueryPasswd($id, ['F_opera_key']);
		if ($record) {
			$oldkey_db = $record->{F_opera_key};
			if ($oldkey_db && $oldkey_db != $jreq->{oldkey}) {
				return ('ERR_OPERA_PASS_WRONG');
			}
			$ret = $db->ModifyPasswd($id, $fieldvals);
		}
		else {
			$ret = $db->CreatePasswd($id, $fieldvals);
		}
	}
	else {
		return ('ERR_ARGUMENT', '密码类型错误');
	}

	if (!$ret) {
		wlog('修改密码表失败');
	}

	return (0, {id => $id, affected => $ret});
}

# 验证会话与操作密码，入参 jreq = req.sess
sub check_session
{
	my ($db, $jreq) = @_;
	
	my $id = $jreq->{id} || return ('ERR_ARGNO_ID');

	my @fields = qw(F_id F_opera_key F_token);
	my $record = $db->QueryPasswd($id, \@fields);
	if ($record) {
		if ($jreq->{opera_key} && $jreq->{opera_key} != $record->{F_opera_key}) {
			return ('ERR_OPERA_PASS_WRONG');
		}
		if ($jreq->{token} && $jreq->{token} != $record->{F_token}) {
			return ('ERR_OPERA_TOKEN_WRONG');
		}
	}
	else {
		wlog("密码表没有记录：$id，正常登陆应该产生记录的");
	}

	return 0;
}
