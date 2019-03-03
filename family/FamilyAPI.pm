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

# _query: 查询成员
#
# 请求：
# req = {
#   all => 全部选择，忽略其他条件
#   page => 第几页
#   perpage => 每页几条记录
#   filter => { 筛选条件
#   id => 单个 id 或 [多个 id 列表]
#   sex => 性别 1/0
#   level => 代际
#   father => 父亲
#   mother => 母亲
#   age => [年龄区间，两个数字]
#   only_tan => 只包含本姓
#   out_xing => 外姓
#   }
#   fields => [需要的列，或默认]
# }
#
# 响应：
# res = {
#   total => 总记录条数
#   page => 第几页
#   perpage => 每页记录数
#   records => [记录列表]
#     每个列表元素是 {请求指定的列}
# }
#
# 返回：($error, $res)
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

	my $where = {};
	if (!$jreq->{all} && $jreq->{filter}) {
		my $filter = $jreq->{filter};
		$where->{F_id} = $filter->{id} if $filter->{id};
		$where->{F_sex} = $filter->{sex} if $filter->{sex};
		$where->{F_level} = $filter->{level} if $filter->{level};
		$where->{F_father} = $filter->{father} if $filter->{father};
		$where->{F_mother} = $filter->{mother} if $filter->{mother};
		# todo 支持更多条件
	}

	$jres = $db->Query($fields, $where, $limit);
	if ($db->{error}) {
		wlog("DB error: $db->{error}");
		$error = 'ERR_DBI_FAILED';
	}
	return ($error, $jres);
}

# _create: 增加成员
#
# 请求：
# req = {
#   id => 写定编号，否则自增
#   name => 姓名
#   sex => 性别
#   father_name => 父亲姓名，通过姓名查 id，有重名或查不到时报错
#   father_id => 直接指定 id ，优先级比姓名高
#   mother_name =>
#   mother_id =>
#   partner_name =>
#   partner_id =>
#   birthday => 生日
#   deathday => 忌日
#   desc => 简介文字
# }
#
# 响应：
# res = {
#   id => 新插入成员的 id
# }
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
		modify_partner($db, $jreq);
	}

	return ($error, $jres);
}

# _modify: 修改成员资料
# 请求：
# req = {
#   id => 只支持用 id 标定一行修改
#   其他参数与 create 相同
# }
# 响应：
# res = {
#    modified => 1
# }
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

	# 额外同步配偶信息
	if ($jreq->{partner_id} || $jreq->{partner_name}) {
		modify_partner($db, $jreq);
	}

	return ($error, $jres);
}

# _remove 删除一个成员
# 请求：
# req = {
#   id => 只支持用 id 标定一行修改
# }
# 响应：
# res = {
#    removed => 1
# }
sub handle_remove
{
	my ($db, $jreq) = @_;
	# todo
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

# 检查双亲关系
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
		$father_level = $records->[0]->{F_level};
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
		$father_level = $records->[0]->{F_level};
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
sub modify_partner
{
	my ($db, $jreq) = @_;
	
	my $mine_id = $jreq->{id};
	return 'ERR_ARGUMENT' unless $mine_id;

	my $records = $db->Query(['F_sex, F_level'], {F_id => $mine_id});
	if ((scalar @$records) < 1) {
		return 'ERR_MEMBER_LACKED';
	}
	my $mine_sex = $records->[0]->{F_sex};
	my $mine_level = $records->[0]->{F_level};

	my $now_time = now_time_str();
	if ($jreq->{partner_id}) {
		wlog('modify by partner id: ' . $jreq->{partner_id});
		my $records = $db->Query(['F_sex, F_level'], {F_id => $jreq->{partner_id}});
		if ((scalar @$records) < 1) {
			return 'ERR_MEMBER_LACKED';
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
			return 'ERR_DBI_FAILED';
		}
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
			return 'ERR_DBI_FAILED';
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
			return 'ERR_DBI_FAILED';
		}
	}
	else {
		return 'ERR_ARGUMENT';
	}

	return 0;
}

sub now_time_str
{
	my $now_obj = DateTime->now;
	my $now_time = $now_obj->ymd . ' ' . $now_obj->hms;
	return $now_time;
}
