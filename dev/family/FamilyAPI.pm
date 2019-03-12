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
};

# 分发响应函数
# req = {api => '接口名', data => {实际请求数据}}
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
	my ($error, $res_data) = $handler->($db, $req_data);
	$db->Disconnect();

	return response($error, $res_data);
}

sub response
{
	my ($error, $data) = @_;

	my $res = { error => $error};
	if ($error) {
		$res->{errmsg} = error_msg($error);
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
    sex => 性别 1/0
    level => 代际
    father => 父亲
    mother => 母亲
    age => [年龄区间，两个数字]
    only_tan => 只包含本姓
    out_xing => 外姓
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
	my $page = $jreq->{page} || 1;
	my $perpage = $jreq->{perpage} || 100;
	my $lb = ($page-1) * $perpage;
	my $ub = ($page) * $perpage;
	my $limit = "$lb,$ub";

	# 默认不选姓名为 '0' 与旁系
	my $where = {F_name => {'!=' => '0'}, F_level => {'>' => 0}};
	if (!$jreq->{all} && $jreq->{filter}) {
		my $filter = $jreq->{filter};
		$where->{F_id} = $filter->{id} if $filter->{id};
		$where->{F_name} = $filter->{name} if $filter->{name};
		$where->{F_sex} = $filter->{sex} if $filter->{sex};
		$where->{F_level} = $filter->{level} if $filter->{level};
		$where->{F_father} = $filter->{father} if $filter->{father};
		$where->{F_mother} = $filter->{mother} if $filter->{mother};
		$where->{F_partner} = $filter->{partner} if $filter->{partner};

		# 模糊查询 name
		if ($filter->{name} =~ /%/) {
			$where->{F_name} = {-like => $filter->{name}};
		}

		if ($filter->{birthday}) {
			my $birthday = $filter->{birthday};
			if (ref($birthday) eq 'ARRAY') {
				$where->{F_birthday} = {-in => $birthday};
			}
			else {
				$where->{F_birthday} = {'>=' => $birthday};
			}
		}

		if ($filter->{deathday}) {
			my $deathday = $filter->{deathday};
			if (ref($deathday) eq 'ARRAY') {
				$where->{F_deathday} = {-in => $deathday};
			}
			else {
				$where->{F_deathday} = {'<=' => $deathday};
			}
		}

		if ($filter->{age}) {
			my $age = $filter->{age};
			if (ref($age) eq 'ARRAY') {
				my $birth_from = DateTime->now->add(years => -$age->[1]);
				my $birth_to = DateTime->now->add(years => -$age->[0]);
				$where->{F_birthday} = {-in => [$birth_from, $birth_to]};
			}
			else {
				my $birth_from = DateTime->now->add(years => -$age->[0]);
				$where->{F_bithathday} = {'>=' => $birth_from};
			}
		}
	}

	# 默认按代际排序
	my $order = 'F_level';
	my $records = $db->Query($fields, $where, $limit, $order);
	if ($db->{error}) {
		wlog("DB error: $db->{error}");
		$error = 'ERR_DBI_FAILED';
		return ($error);
	}

	$jres->{records} = $records;
	$jres->{page} = $page;
	$jres->{perpage} = $perpage;
	my $total = scalar(@{$records});
	if ($total >= $perpage) {
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
    mother_name =>
    mother_id =>
	partner_name => 提供配偶姓名，同时为配偶增加一条记录
	partner_id => 提供配偶 id ，用于给已入库成员修改配偶 id
    birthday => 生日
    deathday => 忌日
    // desc => 简介文字
	requery => 重新查询插入的数据（可能包括配偶）
  }
 
  响应：
  res = {
    id => 新插入成员的 id
	partner_id => 新增或被修改的配偶 id
	records => [] 重查的数据
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
	my $mine_sex = $jreq->{sex} // -1;
	if ($mine_sex != 1 && $mine_sex != 0) {
		return ('ERR_ARGNO_SEX');
	}

	$error = check_parent($db, $jreq);
	return ($error) if $error;

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
	$fieldvals->{F_mother} = $jreq->{mother} if $jreq->{mother};
	$fieldvals->{F_birthday} = $jreq->{birthday} if $jreq->{birthday};
	$fieldvals->{F_deathday} = $jreq->{deathday} if $jreq->{deathday};

	my $now_time = now_time_str();
	$fieldvals->{F_create_time} = $now_time;
	$fieldvals->{F_update_time} = $now_time;

	my $ret = $db->Create($fieldvals);
	if ($db->{error}) {
		wlog("DB error: $db->{error}");
		$error = 'ERR_DBI_FAILED';
	}

	if ($ret != 1) {
		wlog("Expect to insert just one row: $ret");
	}

	if ($jreq->{id}) {
		$jres->{id} = $jreq->{id};
	}
	else {
		$jres->{id} = $db->LastInsertID();
		$jreq->{id} = $jres->{id}; # 更新配偶时要 id 信息
	}

	# 新增成员时同时增加配偶信息
	if ($jreq->{partner_id} || $jreq->{partner_name}) {
		my ($ret_err, $ret_id) = modify_partner($db, $jreq);
		if (!$ret_err) {
			$jres->{partner_id} = $ret_id;
		}
	}

	if ($jreq->{requery}) {
		my $requery = ($jres->{partner_id}) ? [$jres->{id}, $jres->{partner_id}] : $jres->{id};
		my $jqry = {filter => { id => $requery}};
		my ($qry_err, $qry_res) = handle_query($db, $jqry);
		if ($qry_err) {
			$error = $qry_err;
		}
		else {
			$jres->{records} = $qry_res->{records}; 
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
	$fieldvals->{F_name} = $jreq->{name} if $jreq->{name};
	if (defined($jreq->{sex}) && ($jreq->{sex} == 1 || $jreq->{sex} == 0)) {
		$fieldvals->{F_sex} = $jreq->{sex};
	}
	$fieldvals->{F_father} = $jreq->{father} if $jreq->{father};
	$fieldvals->{F_mother} = $jreq->{mother} if $jreq->{mother};
	$fieldvals->{F_birthday} = $jreq->{birthday} if $jreq->{birthday};
	$fieldvals->{F_deathday} = $jreq->{deathday} if $jreq->{deathday};

	my $now_time = now_time_str();
	$fieldvals->{F_update_time} = $now_time;

	my $ret = $db->Modify($fieldvals, { F_id => $mine_id});
	if ($db->{error}) {
		wlog("DB error: $db->{error}");
		$error = 'ERR_DBI_FAILED';
	}

	if ($ret != 1) {
		wlog("Expect to modify just one row");
		$error = 'ERR_DBI_FAILED';
	}

	$jres->{modified} = $ret;
	$jres->{id} = $jreq->{id};

	# 额外同步配偶信息
	if ($jreq->{partner_id} || $jreq->{partner_name}) {
		my ($ret_err, $ret_id) = modify_partner($db, $jreq);
		if (!$ret_err) {
			$jres->{partner_id} = $ret_id;
			$jres->{modified} += 1;
		}
	}

	if ($jreq->{requery}) {
		my $requery = ($jres->{partner_id}) ? [$jres->{id}, $jres->{partner_id}] : $jres->{id};
		my $jqry = {filter => { id => $requery}};
		my ($qry_err, $qry_res) = handle_query($db, $jqry);
		if ($qry_err) {
			$error = $qry_err;
		}
		else {
			$jres->{records} = $qry_res->{records}; 
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
	my $error = 0;
	my $jres = {};

	my $mine_id = $jreq->{id}
		or return('ERR_ARGNO_ID');
	my $where = {F_id => $mine_id};

	my $ret = $db->Remove($where);
	if ($db->{error}) {
		wlog("DB error: $db->{error}");
		$error = 'ERR_DBI_FAILED';
	}

	if ($ret != 1) {
		wlog("Expect to delete just one row");
		$error = 'ERR_DBI_FAILED';
	}

	$jres->{removed} = $ret;

	return ($error, $jres);
}

# 检查双亲关系，返回错误码
sub check_parent
{
	my ($db, $jreq) = @_;
	
	my $error = 0;

	# 父亲关系
	my $father_level = 0;
	if ($jreq->{father_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{father_id}});
		if ((scalar @$records) < 1) {
			return 'ERR_MEMBER_LACKED';
		}
		$jreq->{father} = $jreq->{father_id};
		$father_level = abs($records->[0]->{F_level});
	}
	elsif ($jreq->{father_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{father_name}});
		if ((scalar @$records) < 1) {
			return 'ERR_NAME_LACKED';
		}
		elsif ((scalar @$records) > 1) {
			return 'ERR_NAME_DUPED';
		}
		$jreq->{father} = $records->[0]->{F_id};
		$father_level = abs($records->[0]->{F_level});
	}

	# 母亲关系
	my $mother_level = 0;
	if ($jreq->{mother_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{mother_id}});
		if ((scalar @$records) < 1) {
			return 'ERR_MEMBER_LACKED';
		}
		$jreq->{mother} = $jreq->{mother_id};
		$mother_level = abs($records->[0]->{F_level});
	}
	elsif ($jreq->{mother_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{mother_name}});
		if ((scalar @$records) < 1) {
			return 'ERR_NAME_LACKED';
		}
		elsif ((scalar @$records) > 1) {
			return 'ERR_NAME_DUPED';
		}
		$jreq->{mother} = $records->[0]->{F_id};
		$mother_level = abs($records->[0]->{F_level});
	}

	if (!$father_level && !$mother_level) {
		return 'ERR_PARENT_LACKED';
	}

	my $level;
	if ($father_level && !$mother_level) {
		$level = $father_level;
	}
	elsif (!$father_level && $mother_level) {
		$level = $mother_level;
	}
	elsif ($father_level != $mother_level) {
		return 'ERR_PARENT_DISMATCH';
	}
	else {
		$level = $father_level;
	}

	$jreq->{level} = $level + 1;
	return $error;
}

# 修改并同步配偶信息
# 如果提供姓名 partner_name ，为配偶新增一条记录
# 返回错误码与配偶的 id
sub modify_partner
{
	my ($db, $jreq) = @_;
	
	my $mine_id = $jreq->{id};
	return ('ERR_ARGUMENT', 0) unless $mine_id;

	my $records = $db->Query(['F_sex, F_level'], {F_id => $mine_id});
	if ((scalar @$records) < 1) {
		return ('ERR_MEMBER_LACKED', 0);
	}
	my $mine_sex = $records->[0]->{F_sex};
	my $mine_level = $records->[0]->{F_level};

	my $now_time = now_time_str();
	if ($jreq->{partner_id}) {
		wlog('modify by partner id: ' . $jreq->{partner_id});
		my $records = $db->Query(['F_sex, F_level'], {F_id => $jreq->{partner_id}});
		if ((scalar @$records) < 1) {
			return ('ERR_MEMBER_LACKED', 0);
		}

		# 检查后直接修改自己的信息
		my $fieldvals = {};
		$fieldvals->{F_update_time} = $now_time;
		$fieldvals->{F_partner} = $jreq->{partner_id};
		if (!$mine_sex) {
			$fieldvals->{F_sex} = 1 - $records->[0]->{F_sex};
		}
		if (!$mine_level) {
			$fieldvals->{F_level} = 0 - $records->[0]->{F_level};
		}
		my $ret = $db->Modify($fieldvals, { F_id => $mine_id});
		if ($db->{error}) {
			wlog("DB error: $db->{error}");
			return ('ERR_DBI_FAILED', 0);
		}

		return (0, $jreq->{partner_id});
	}
	elsif ($jreq->{partner_name}) {
		wlog('modify by partner name ' . $jreq->{partner_name});

		# 新增配偶记录
		my $fieldvals = {};
		$fieldvals->{F_name} = $jreq->{partner_name};
		$fieldvals->{F_partner} = $mine_id;
		$fieldvals->{F_level} = 0 - $mine_level;
		$fieldvals->{F_sex} = 1 - $mine_sex;
		$fieldvals->{F_update_time} = $now_time;
		$fieldvals->{F_create_time} = $now_time;
		my $ret = $db->Create($fieldvals);
		if ($db->{error}) {
			wlog("DB error: $db->{error}");
			return ('ERR_DBI_FAILED', 0);
		}
		if ($ret != 1) {
			wlog("Expect to insert just one row");
		}
		my $partner_id = $db->LastInsertID();

		# 修改自己的信息
		$fieldvals = {};
		$fieldvals->{F_update_time} = $now_time;
		$fieldvals->{F_partner} = $partner_id;
		$ret = $db->Modify($fieldvals, { F_id => $mine_id});
		if ($db->{error}) {
			wlog("DB error: $db->{error}");
			return ('ERR_DBI_FAILED', 0);
		}

		return (0, $partner_id);
	}
	else {
		return ('ERR_ARGUMENT', 0);
	}

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
  partner => 1/0 包含配偶
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

	# 查配偶
	if ($jreq->{partner} && $row_mine->{F_partner}) {
		$filter = {partner => $id};
		($qry_err, $qry_res) = handle_query($db, {filter => $filter});
		if (!$qry_err && $qry_res->{records}) {
			$jres->{partner} = $qry_res->{records};
		}
	}

	# 查孩子
	if ($jreq->{children}) {
		if ($row_mine->{F_sex} == 1) {
			$filter = {father => $id};
		}
		else {
			$filter = {mother => $id};
		}
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
			if ($parent->{F_sex} == 1) {
				$filter = {father => $parent->{F_id}};
			}
			else {
				$filter = {mother => $parent->{F_id}};
			}
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

# 根据自己这行，查找直系父母（代际大于0）那行，失败时返回 undef
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
	if ($row_mine->{F_mother}) {
		my $parent = query_single($db, $row_mine->{F_mother});
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
