#! /usr/bin/env perl
use utf8;
package DiaochaAPI;
use strict;
use warnings;

use WebLog;
use MYDB;
use DateTime;

# 数据库连接信息
my $dbcfg = {
	host => '47.106.142.119',
	user => 'kaihe',
	pass => '0xKaiHe',
	# port => 0,
	# flag => {},
	database => 'db_kaihe',
	table => 't_diaocha',
};

my $TABLE_DIAOCHA = 't_diaocha';
my @FIELD_DIAOCHA = qw(F_room F_pass F_json F_create_time F_update_time);

# 错误码设计
my $MESSAGE_REF = {
	ERR_SUCCESS => '0. 成功',
	ERR_SYSTEM => '-1. 系统错误',
	ERR_SYSNO_API => '-2. 系统错误，缺少接口，请检查接口名',
	ERR_ARGUMENT => '1. 参数错误',
	ERR_ARGNO_API => '2. 参数错误，缺少接口名字',
	ERR_ARGNO_DATA => '3. 参数错误，缺少接口数据',
	ERR_ARGNO_ID => '5. 参数错误，缺少ID',
	ERR_ARGNO_SESS => '6. 参数错误，缺少用户密码或其他会话参数',
	ERR_USER_PASS => '7. 用户名或密码错误',
	ERR_DBI_FAILED => '10. 数据库操作失败',
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

# 请求入口，分发响应函数
# req = {api => '接口名', data => {实际请求数据}, sess=>{会话及操作密码}}
# 修改数据库操作将验证 sess
sub handle_request
{
	my ($jreq) = @_;

	if ($jreq->{sess} && $jreq->{sess}->{version} eq 'test') {
		$dbcfg->{database} = 'db_kaihe_test';
	}

	my $api = $jreq->{api}
		or return response('ERR_ARGNO_API');
	my $req_data = $jreq->{data}
		or return response('ERR_ARGNO_DATA');
	my $handler = $HANDLER->{$api}
		or return response('ERR_SYSNO_API');

	my $db = MYDB->new($dbcfg);

	if ($db->{error}) {
		return response('ERR_DBI_FAILED', $db->{error});
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
  _query: 查询调查记录
 
请求：
  req = {
    room => string
  }
 
响应：
  res = {
	room => string
	json => string
	create_time => string
	update_time => string
  }
 
返回：
  ($error, $res)
=cut
sub handle_query
{
	my ($db, $jreq, $private) = @_;
	my $error = 0;
	my $jres = {};

	if (!$jreq->{room}) {
		return ('ERR_ARGUMENT');
	}

	my $fields = \@FIELD_DIAOCHA;
	my $where = {F_room => $jreq->{room}};

	my $order = undef;
	my $records = $db->Query($fields, $where, undef, $order);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if (scalar(@{$records}) <= 0) {
		$jres->{room} = undef;
		return ($error, $jres);
	}

	my $res = $records->[0];
	return ('ERR_DBI_FAILED') unless ($res);
	$jres->{room} = $res->{F_room};
	$jres->{json} = $res->{F_json};
	$jres->{create_time} = $res->{F_create_time};
	$jres->{update_time} = $res->{F_update_time};

	if ($private) {
		$jres->{pass} = $res->{F_pass};
	}

	return ($error, $jres);
}

=sub handle_create()
  _create: 增加调查记录
 
  请求：
  req = {
	room => string
	pass => string
	json => string
  }
 
  响应：
  res = {
    created => 签到插入的行数
    room => 原路返回 id
  }
=cut
sub handle_create
{
	wlog('headle this ...');
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	if (!$jreq->{room} || !$jreq->{pass}) {
		return ('ERR_ARGUMENT');
	}

	my $now = now_time_str();
	my $fieldvals = {
		F_room => $jreq->{room},
		F_json => $jreq->{json},
		F_pass => $jreq->{pass},
		F_create_time => $now,
		F_update_time => $now,
	};

	my $ret = $db->Create($fieldvals);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to insert just one row: $ret");
	}

	$jres->{created} = 1;
	$jres->{room} = $jreq->{room};

	return ($error, $jres);
}

=sub handle_modify()
  _modify: 修改签到表
 
  请求：
  req = {
	room => string
	pass => string
	json => string
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

	if (!$jreq->{room} || !$jreq->{pass}) {
		return ('ERR_ARGUMENT');
	}

	my ($query_error, $query_data) = handle_query($db, $jreq, 1);
	if ($query_error) {
		return ($query_error);
	}
	if ($query_data->{pass} != $jreq->{pass}) {
		return ('ERR_USER_PASS');
	}

	my $now = now_time_str();
	my $fieldvals = {};
	$fieldvals->{F_json} = $jreq->{json};
	$fieldvals->{F_update_time} = $now;

	my $ret = $db->Modify($fieldvals, {F_room => $jreq->{room}});
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
	if ($ret != 1) {
		wlog("Expect to modify just one row");
		return ('ERR_DBI_FAILED');
	}
	$jres->{modified} = 1;

	return ($error, $jres);
}

=sub handle_remove()
 _remove 删除一个调查记录
 请求：
 req = {
   room => string
 }
 响应：
 res = {
    removed => 1
 }
=cut
sub handle_remove
{
	my ($db, $jreq) = @_;
	# 暂时不做删除

	return (0, {removed => 0});
}

sub now_time_str
{
	my $now_obj = DateTime->now;
	my $now_time = $now_obj->ymd . ' ' . $now_obj->hms;
	return $now_time;
}

