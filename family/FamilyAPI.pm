#! /usr/bin/env perl
use utf8;
package FamilyAPI;
use strict;
use warnings;

use WebLog;
use FamilyDB;

# 响应函数配置
# 响应函数要求返回两个值，错误码及实际数据
my $handler = {
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
	my $action = $jreq->{action};
	my $req_data = $jreq->{data};
	my ($error, $res_data) = $handler->{$action}->($req_data);
	my $res = { error => $error, data => $res_data };
	if ($error != 0) {
		$res->{errmsg} = error_msg($error);
	}
	return $res;
}

# 错误码设计
my $MESSAGE_REF = {};
my $ERR_SYSTEM = -1; $MESSAGE_REF->{$ERR_SYSTEM} = '系统错误';
my $ERR_ARGUMENT = 1; $MESSAGE_REF->{$ERR_ARGUMENT} = '参数错误';
my $ERR_NAME_DUPED = 2; $MESSAGE_REF->{$ERR_NAME_DUPED} = '发现重名，请用ID';

sub error_msg
{
	my ($error) = @_;
	return $MESSAGE_REF->{$error};
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
	my ($jreq) = @_;
	my $error = 0;
	my $jres = {};

	return ($error, $jres);
}

# _create: 增加成员
#
# 请求：
# req = {
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
	my ($jreq) = @_;
	my $error = 0;
	my $jres = {};

	$error = $ERR_NAME_DUPED;
	$jres->{id} = 123;

	return ($error, $jres);
}

sub handle_modify
{
	my ($jreq) = @_;
	my $error = 0;
	my $jres = {};

	return ($error, $jres);
}

sub handle_remove
{
	my ($jreq) = @_;
	# todo
	my $error = 0;
	my $jres = {};

	return ($error, $jres);
}

