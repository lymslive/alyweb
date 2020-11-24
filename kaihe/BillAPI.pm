#! /usr/bin/env perl
use utf8;
package BillAPI;
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
	table => 't_bill',
};

my $TABLE_BILL = 't_bill';
my @FIELD_BILL = qw(F_flow F_date F_type F_subtype F_room F_money F_balance F_note);

# 错误码设计
my $MESSAGE_REF = {
	ERR_SUCCESS => '0. 成功',
	ERR_SYSTEM => '-1. 系统错误',
	ERR_SYSNO_API => '-2. 系统错误，缺少接口，请检查接口名',
	ERR_ARGUMENT => '1. 参数错误',
	ERR_ARGNO_API => '2. 参数错误，缺少接口名字',
	ERR_ARGNO_DATA => '3. 参数错误，缺少接口数据',
	ERR_ARGNO_ID => '5. 参数错误，缺少ID',
	ERR_ARGONLY_LASTID => '5. 参数错误，只能修改最后一条记录',
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

	if ($api eq 'create' || $api eq 'modify') {
		if (!$jreq->{sess}) {
			return response('ERR_ARGNO_SESS');
		}
		my $admin = $jreq->{sess}->{admin};
		my $password = $jreq->{sess}->{password};
		if ($password ne $PASSWORD->{$admin}) {
			return response('ERR_USER_PASS');
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

=sub handle_query()
  _query: 查询帐单

请求：
  req = {
	limit => 限制数量，默认100
	flow => flow_id, 可有前缀 <=>
  }

响应：
  res = {
	count => 记录数
	records => [记录列表]
	  每个列表元素含 {flow, date, type, subtype, room, money, balance, note}
  }

返回：
  ($error, $res)
=cut
sub handle_query
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	my $fields = \@FIELD_BILL;

	my $limit = $jreq->{limit};
	if (!$limit || $limit > 100 || $limit < 1) {
		$limit = 100;
	}

	my $where = {};
	if ($jreq->{flow}) {
		if ($jreq->{flow} =~ '^([<=>]+)?(\d+)$') {
			my $cmp = $1;
			my $val = $2;
			if (!$cmp) {
				$where->{F_flow} = $val;
			}
			else {
				$where->{F_flow} = {$cmp => $val};
			}
		}
		else {
			return ('ERR_ARGUMENT', 'invalid flow id/compare');
		}
	}

	my $order = {'-desc' => 'F_flow'};
	my $records = $db->Query($fields, $where, $limit, $order);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	my $bills = [];
	my $count = scalar(@{$records});
	foreach my $record (@$records) {
		push(@$bills, {
				flow => $record->{F_flow},
				date => $record->{F_date},
				type => $record->{F_type},
				subtype => $record->{F_subtype},
				room => $record->{F_room},
				money => $record->{F_money},
				balance => $record->{F_balance},
				note => $record->{F_note},
			});
	}

	$jres->{records} = $bills;
	return ($error, $jres);
}

=sub handle_create()
  _create: 增加帐单

  请求：
  req = {
	// bill 记录，flow 自动生成，banlance 自动计算
	date, type, subtype, room, money, note
	requery => 重新查询插入的数据
  }

  响应：
  res = {
	created => 1
	flow => 新插入的 id
	balance => 当前余额
	mine => {} 重查的记录
  }
=cut
sub handle_create
{
	wlog('headle this ...');
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	if (!$jreq->{date} || !$jreq->{type} || !$jreq->{money}) {
		return ('ERR_ARGUMENT');
	}

	my $bill = {
		F_date => $jreq->{date},
		F_type => $jreq->{type},
		F_subtype => $jreq->{subtype},
		F_room => $jreq->{room},
		F_money => $jreq->{money},
		F_note => $jreq->{note},
	};
	my $now_time = now_time_str();
	$bill->{F_update_time} = $now_time;
	$bill->{F_create_time} = $now_time;

	my $last = query_last($db);
	if (!$last) {
		$last = {F_flow => 0, F_balance => 0};
	}

	my $diff = $bill->{F_money} * $bill->{F_type};
	$bill->{F_flow} = $last->{flow} + 1;
	$bill->{F_balance} = $last->{balance} + $diff;

	my $ret = $db->Create($bill);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to insert just one row: $ret");
	}

	$jres->{created} = $ret;
	$jres->{flow} = $bill->{F_flow};
	$jres->{balance} = $bill->{F_balance};

	if ($jreq->{requery}) {
		$jres->{mine} = query_single($db, $jres->{flow});
	}

	return ($error, $jres);
}

=sub handle_modify()
  _modify: 修改帐单
  请求：
  req = {
	// bill 记录，banlance 自动调整
	// 只能修改最后一条记录的 money ，不能修改 type
	flow, date, type, room, money, note
	requery => 重新查询插入的数据
  }
  响应：
  res = {
	modified => 1
	mine => {} 重查的记录
  }
=cut
sub handle_modify
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	my $flow = $jreq->{flow} or return('ERR_ARGNO_ID');
	my $bill = {};
	my $now_time = now_time_str();
	$bill->{F_update_time} = $now_time;
	if ($jreq->{date}) {
		$bill->{F_date} = $jreq->{date};
	}
	if ($jreq->{subtype}) {
		$bill->{F_subtype} = $jreq->{subtype};
	}
	if ($jreq->{room}) {
		$bill->{F_room} = $jreq->{room};
	}
	if ($jreq->{note}) {
		$bill->{F_note} = $jreq->{note};
	}

	if ($jreq->{money}) {
		my $last = query_last($db);
		if (!$last) {
			return ('ERR_ARGONLY_LASTID');
		}
		if ($flow == $last->{flow} && $jreq->{money} != $last->{money}) {
			$bill->{F_money} = $jreq->{money};
			my $diff = $bill->{F_money} - $last->{money};
			if ($diff != 0 && $last->{F_type} < 0) {
				$diff = - $diff;
			}
			$bill->{F_balance} = $last->{balance} + $diff;
		}
	}

	my $ret = $db->Modify($bill, {F_flow => $flow});
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to modify just one row");
		$error = 'ERR_DBI_FAILED';
	}

	$jres->{modified} = $ret;

	if ($jreq->{requery}) {
		$jres->{mine} = query_single($db, $flow);
	}

	return ($error, $jres);
}

=sub handle_remove()
 _remove 删除一个成员
 请求：
 req = {
   flow => 待删除 id ，只能删除最后一个记录
 }
 响应：
 res = {
	removed => 1
 }
=cut
sub handle_remove
{
	my ($db, $jreq) = @_;
	my $flow = $jreq->{flow} or return('ERR_ARGNO_ID');

	my $last = query_last($db);
	if (!$last || $last->{flow} != $flow) {
		return ('ERR_ARGONLY_LASTID');
	}
	my $where = {F_flow => $flow};
	my $ret = $db->Remove($where);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
	return ('ERR_DBI_FAILED', "Expect to delete just one row") if ($ret != 1);

	return (0, {removed => $ret});
}

sub now_time_str
{
	my $now_obj = DateTime->now;
	my $now_time = $now_obj->ymd . ' ' . $now_obj->hms;
	return $now_time;
}


# 按 flow id 查询单行，直接返回记录 hashref ，不存在时返回 undef
sub query_single
{
	my ($db, $id) = @_;
	my ($qry_err, $qry_res) = handle_query($db, {flow => $id, limit => 1});
	if ($qry_err || !$qry_res->{records}) {
		return undef;
	}
	return $qry_res->{records}->[0];
}

# 查最后一行
sub query_last
{
	my ($db) = @_;
	my ($qry_err, $qry_res) = handle_query($db, {limit => 1});
	if ($qry_err || !$qry_res->{records}) {
		return undef;
	}
	# when empty table
	if (scalar(@{$qry_res->{records}}) == 0) {
		return undef;
	}
	return $qry_res->{records}->[0];
}

=head1 config table operate
=cut

