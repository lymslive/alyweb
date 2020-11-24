#! /usr/bin/env perl
use utf8;
package SignAPI;
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
	table => 't_signup',
};

my $TABLE_SIGNUP = 't_signup';
my @FIELD_SIGNUP = qw(F_date F_room F_state);
my $TABLE_EVENT = 't_event';
my @FIELD_EVENT = qw(F_date F_short F_long);

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

my $PASSWORD = {
	'B1406' => 'kh0405',
	'A504'  => 'haimei',
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

	# 一个接口可能要联表修改 signup 与 event 表
	# 实际用不到以下接口
	query_event => \& handle_query_event,
	# create_event => \& handle_create_event,
	# modify_event => \& handle_modify_event,
	# remove_event => \& handle_remove_event,
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

	if ($api eq 'create' || $api eq 'modify') {
		if (!$jreq->{sess}) {
			return response('ERR_ARGNO_SESS');
		}
		my $admin = $jreq->{sess}->{admin};
		my $password = $jreq->{sess}->{password};
		if ($admin eq 'test') {
			$dbcfg->{database} = 'db_kaihe_test';
		}
		else {
			$dbcfg->{database} = 'db_kaihe';
			if ($password ne $PASSWORD->{$admin}) {
				return response('ERR_USER_PASS');
			}
		}
	}

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

=sub handle_query_event()
  _query_event: 查询签到表

请求：
  req = { null }

响应：
  res = {
	date => [date list]
	short => [name list]
  }

返回：
  ($error, $res)
=cut
sub handle_query_event
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	$db->{table} = $TABLE_EVENT;
	my $fields = ['F_date', 'F_short'];
	my $where = undef;

	my $order = ['F_date'];
	my $records = $db->Query($fields, undef, undef, $order);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	my $date = [];
	my $short = [];
	foreach my $record (@$records) {
		push(@$date, $record->{F_date});
		push(@$short, $record->{F_short});
	}
	$jres->{date} = $date;
	$jres->{short} = $short;

	return ($error, $jres);
}

=sub handle_query()
  _query: 查询签表记录
 
请求：
  req = {
    date => string
  }
 
响应：
  res = {
	date => string
	short => string
	long => string
	signed => [{room, state}]
  }
 
返回：
  ($error, $res)
=cut
sub handle_query
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	if (!$jreq->{date}) {
		return ('ERR_ARGUMENT');
	}

	$db->{table} = $TABLE_EVENT;
	my $fields = \@FIELD_EVENT;
	my $where = {F_date => $jreq->{date}};

	my $order = ['F_date'];
	my $records = $db->Query($fields, $where, undef, $order);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	my $event = $records->[0];
	return ('ERR_DBI_FAILED') unless ($event);
	$jres->{date} = $event->{F_date};
	$jres->{short} = $event->{F_short};
	$jres->{long} = $event->{F_long};

	$db->{table} = $TABLE_SIGNUP;
	$fields = \@FIELD_SIGNUP;
	$where = {F_date => $jreq->{date}};
	$order = ['F_date', 'F_room'];
	$records = $db->Query($fields, $where, undef, $order);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
	
	my $signed = [];
	foreach my $record (@$records) {
		push(@$signed, {room => $record->{F_room}, state => $record->{F_state}});
	}
	$jres->{signed} = $signed;

	return ($error, $jres);
}

=sub handle_create()
  _create: 增加签到记录
 
  请求：
  req = {
	date => string
	short => string
	long => string
	signed => [{room, state}]
  }
 
  响应：
  res = {
    created => 签到插入的行数
    date => 新插入的 id
  }
=cut
sub handle_create
{
	wlog('headle this ...');
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	if (!$jreq->{date}) {
		return ('ERR_ARGUMENT');
	}

	# 先插入事件表
	$db->{table} = $TABLE_EVENT;
	my $fieldvals = {F_date => $jreq->{date}, F_short => $jreq->{short}, F_long =>$jreq->{long}};

	my $ret = $db->Create($fieldvals);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to insert just one row: $ret");
	}

	$jres->{created} = 0;
	$jres->{date} = $jreq->{date};

	# 再插入签到表
	$db->{table} = $TABLE_SIGNUP;
	my $singed = $jreq->{signed};
	foreach my $sign (@$singed) {
		my $fieldvals = {F_date => $jreq->{date}, F_room => $sign->{room}, F_state => $sign->{state}};
		my $ret = $db->Create($fieldvals);
		return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
		$jres->{created} = $jres->{created} + 1;
	}
	
	return ($error, $jres);
}

=sub handle_modify()
  _modify: 修改签到记录
 
  请求：
  req = {
	date => string
	short => string
	long => string
	sined => [{room, state}]
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

	if (!$jreq->{date}) {
		return ('ERR_ARGUMENT');
	}

	# 先修改事件表
	if ($jreq->{short} || $jreq->{long}) {
		$db->{table} = $TABLE_EVENT;
		my $fieldvals = {};
		if ($jreq->{short}) {
			$fieldvals->{F_short} = $jreq->{short};
		}
		if ($jreq->{long}) {
			$fieldvals->{F_long} = $jreq->{long};
		}
		my $ret = $db->Modify($fieldvals, {F_date => $jreq->{date}});
		return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
		if ($ret != 1) {
			wlog("Expect to modify just one row");
			return ('ERR_DBI_FAILED');
		}
		$jres->{modified} = 1;
	}

	if ($jreq->{signed} && scalar(@{$jreq->{signed}}) > 0) {
		$db->{table} = $TABLE_SIGNUP;
		$jres->{modified} = 0;
		my $singed = $jreq->{signed};
		foreach my $sign (@$singed) {
			my $fieldvals = {F_state => $sign->{state}};
			my $where = {F_date => $jreq->{date}, F_room => $sign->{room}};
			my $ret = $db->Modify($fieldvals, $where);
			if ($db->{error} || $ret != 1) {
				$fieldvals = {F_date => $jreq->{date}, F_room => $sign->{room}, F_state => $sign->{state}};
				$ret = $db->Create($fieldvals);
				return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
			}
			$jres->{modified} = $jres->{modified} + 1;
		}
	}

	return ($error, $jres);
}

=sub handle_remove()
 _remove 删除一个签到记录
 请求：
 req = {
   date => string
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

