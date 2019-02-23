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
# req = {action => '接口名', data => {实际请求数据}}
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
		or return('ERR_ARGNO_NAME');
	my $mine_sex = $jreq->{sex}
		or return('ERR_ARGNO_SEX');

	my $fieldvals = {};
	$fieldvals->{F_name} = $mine_name;
	$fieldvals->{F_sex} = $mine_sex;

	$fieldvals->{F_id} = $jreq->{id} if $jreq->{id};
	$fieldvals->{F_birthday} = $jreq->{birthday} if $jreq->{birthday};
	$fieldvals->{F_deathday} = $jreq->{deathday} if $jreq->{deathday};

	# 父亲关系
	if ($jreq->{father_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{father_id}});
		if ((scalar @$records) < 1) {
			$error = 'ERR_NAME_LACKED';
			return ($error, $jres);
		}
		$fieldvals->{F_father} = $jreq->{father_id};
		$fieldvals->{F_level} = $records->[0]->{F_level} + 1;
	}
	elsif ($jreq->{father_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{father_name}});
		if ((scalar @$records) < 1) {
			$error = 'ERR_NAME_LACKED';
			return ($error, $jres);
		}
		elsif ((scalar @$records) > 1) {
			$error = 'ERR_NAME_DUPED';
			return ($error, $jres);
		}
		$fieldvals->{F_father} = $records->[0]->{F_id};
		$fieldvals->{F_level} = $records->[0]->{F_level} + 1;
	}

	# 母亲关系
	if ($jreq->{mother_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{mother_id}});
		if ((scalar @$records) < 1) {
			$error = 'ERR_NAME_LACKED';
			return ($error, $jres);
		}
		$fieldvals->{F_mother} = $jreq->{mother_id};
		$fieldvals->{F_level} //= abs($records->[0]->{F_level}) + 1;
	}
	elsif ($jreq->{mother_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{mother_name}});
		if ((scalar @$records) < 1) {
			$error = 'ERR_NAME_LACKED';
			return ($error, $jres);
		}
		elsif ((scalar @$records) > 1) {
			$error = 'ERR_NAME_DUPED';
			return ($error, $jres);
		}
		$fieldvals->{F_mother} = $records->[0]->{F_id};
		$fieldvals->{F_level} //= abs($records->[0]->{F_level}) + 1;
	}

	# 配偶关系
	if ($jreq->{partner_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{partner_id}});
		if ((scalar @$records) < 1) {
			$error = 'ERR_NAME_LACKED';
			return ($error, $jres);
		}
		$fieldvals->{F_partner} = $jreq->{partner_id};
		$fieldvals->{F_level} //= 0 - $records->[0]->{F_level};
	}
	elsif ($jreq->{partner_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{partner_name}});
		if ((scalar @$records) < 1) {
			$error = 'ERR_NAME_LACKED';
			return ($error, $jres);
		}
		elsif ((scalar @$records) > 1) {
			$error = 'ERR_NAME_DUPED';
			return ($error, $jres);
		}
		$fieldvals->{F_partner} = $records->[0]->{F_id};
		$fieldvals->{F_level} //= 0 - $records->[0]->{F_level};
	}

	unless ($fieldvals->{F_level}) {
		$error = 'ERR_ARGNO_RELATE';
		return ($error, $jres);
	}

	my $now_time = now_time_str();
	$fieldvals->{F_create_time} = $now_time;
	$fieldvals->{F_update_time} = $now_time;

	my $ret = $db->Create($fieldvals);
	if ($db->{error}) {
		wlog("DB error: $db->{error}");
		$error = 'ERR_DBI_FAILED';
	}

	if ($ret != 1) {
		wlog("Expect to insert just one row");
	}

	if ($jreq->{id}) {
		$jres->{id} = $jreq->{id};
	}
	else {
		$jres->{id} = $db->LastInsertID();
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

	my $fieldvals = {};
	$fieldvals->{F_name} = $jreq->{name} if $jreq->{name};
	$fieldvals->{F_sex} = $jreq->{sex} if $jreq->{sex};
	$fieldvals->{F_birthday} = $jreq->{birthday} if $jreq->{birthday};
	$fieldvals->{F_deathday} = $jreq->{deathday} if $jreq->{deathday};

	# 父亲关系
	if ($jreq->{father_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{father_id}});
		if ((scalar @$records) == 1) {
			$fieldvals->{F_father} = $jreq->{father_id};
			$fieldvals->{F_level} = $records->[0]->{F_level} + 1;
		}
		else {
			wlog("Ingore invalid id: " . $jreq->{father_id});
		}
	}
	elsif ($jreq->{father_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{father_name}});
		if ((scalar @$records) == 1) {
			$fieldvals->{F_father} = $records->[0]->{F_id};
			$fieldvals->{F_level} = $records->[0]->{F_level} + 1;
		}
		else {
			wlog("Ingore invalid name: " . $jreq->{father_name});
		}
	}

	# 母亲关系
	if ($jreq->{mother_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{mother_id}});
		if ((scalar @$records) == 1) {
			$fieldvals->{F_mother} = $jreq->{mother_id};
			$fieldvals->{F_level} = abs($records->[0]->{F_level}) + 1;
		}
		else {
			wlog("Ingore invalid id: " . $jreq->{mother_id});
		}
	}
	elsif ($jreq->{mother_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{mother_name}});
		if ((scalar @$records) == 1) {
			$fieldvals->{F_mother} = $records->[0]->{F_id};
			$fieldvals->{F_level} = abs($records->[0]->{F_level}) + 1;
		}
		else {
			wlog("Ingore invalid name: " . $jreq->{mother_name});
		}
	}

	# 配偶关系
	if ($jreq->{partner_id}) {
		my $records = $db->Query(['F_level'], {F_id => $jreq->{partner_id}});
		if ((scalar @$records) == 1) {
			$fieldvals->{F_partner} = $jreq->{partner_id};
			$fieldvals->{F_level} = 0 - $records->[0]->{F_level};
		}
		else {
			wlog("Ingore invalid id: " . $jreq->{partner_id});
		}
	}
	elsif ($jreq->{partner_name}) {
		my $records = $db->Query(['F_id, F_level'], {F_name => $jreq->{partner_name}});
		if ((scalar @$records) == 1) {
			$fieldvals->{F_partner} = $records->[0]->{F_id};
			$fieldvals->{F_level} = 0 - $records->[0]->{F_level};
		}
		else {
			wlog("Ingore invalid name: " . $jreq->{partner_name});
		}
	}

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

sub now_time_str
{
	my $now_obj = DateTime->now;
	my $now_time = $now_obj->ymd . ' ' . $now_obj->hms;
	return $now_time;
}
