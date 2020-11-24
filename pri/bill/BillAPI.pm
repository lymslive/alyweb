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
	user => 'family',
	pass => '0xFAFAFA',
	# port => 0,
	# flag => {},
	database => 'db_bill',
	table => 't_family_bill',
};

my $TABLE_BILL = 't_family_bill';
my @FIELD_BILL = qw(F_id F_type F_subtype F_money F_date F_time F_target F_place F_note);
my $TABLE_CONFIG = 't_type_config';
my @FIELD_CONFIG = qw(F_subtype F_typename);

# 错误码设计
my $MESSAGE_REF = {
	ERR_SUCCESS => '0. 成功',
	ERR_SYSTEM => '-1. 系统错误',
	ERR_SYSNO_API => '-2. 系统错误，缺少接口，请检查接口名',
	ERR_ARGUMENT => '1. 参数错误',
	ERR_ARGNO_API => '2. 参数错误，缺少接口名字',
	ERR_ARGNO_DATA => '3. 参数错误，缺少接口数据',
	ERR_ARGNO_ID => '5. 参数错误，缺少ID',
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

	query_config => \& handle_query_config,
	create_config => \& handle_create_config,
	modify_config => \& handle_modify_config,
	remove_config => \& handle_remove_config,
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

	my $db = MYDB->new($dbcfg);
	if ($api =~ /config$/) {
		$db->{table} = $TABLE_CONFIG;
	}

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
    all => 全部选择，忽略其他条件
    page => 第几页
    perpage => 每页几条记录
    where => { 筛选条件
	  直接指定 F_field 条件
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
	my $fields = $jreq->{fields} // \@FIELD_BILL;

	# 计算 limit 分页上下限
	my $page = 0 + $jreq->{page} || 1;
	my $perpage = 0 + $jreq->{perpage} || 100;
	my $lb = ($page-1) * $perpage;
	my $ub = ($page) * $perpage;
	my $limit = "$lb,$perpage";

	my $where = {};
	if (!$jreq->{all} && $jreq->{where}) {
		$where = $jreq->{where};
	}

	my $order = ['F_date'];
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
  _create: 增加帐单
 
  请求：
  req = {
	fieldvals => {直接指定字段值}
	requery => 重新查询插入的数据
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

	my $fieldvals = $jreq->{fieldvals};
	my $now_time = now_time_str();
	$fieldvals->{F_update_time} = $now_time;

	my $ret = $db->Create($fieldvals);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to insert just one row: $ret");
	}

	$jres->{created} = $ret;
	if ($fieldvals->{F_id}) {
		$jres->{F_id} = $fieldvals->{F_id};
	}
	else {
		$jres->{F_id} = $db->LastInsertID();
	}

	if ($jreq->{requery}) {
		$jres->{mine} = query_single($db, $jres->{F_id});
	}

	return ($error, $jres);
}

=sub handle_modify()
  _modify: 修改帐单
  请求：
  req = {
	fieldvals => {直接指定字段值, 必须有 F_id}
	requery => 重新查询插入的数据
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

	my $fieldvals = $jreq->{fieldvals};
	my $now_time = now_time_str();
	$fieldvals->{F_update_time} = $now_time;
	my $mine_id = $fieldvals->{F_id}
		or return('ERR_ARGNO_ID');
	delete $fieldvals->{F_id};

	my $ret = $db->Modify($fieldvals, { F_id => $mine_id});
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});

	if ($ret != 1) {
		wlog("Expect to modify just one row");
		$error = 'ERR_DBI_FAILED';
	}

	$jres->{modified} = $ret;
	$jres->{F_id} = $mine_id;

	if ($jreq->{requery}) {
		$jres->{mine} = query_single($db, $jres->{F_id});
	}

	return ($error, $jres);
}

=sub handle_remove()
 _remove 删除一个成员
 请求：
 req = {
   F_id => 只支持用 id 标定一行修改
 }
 响应：
 res = {
    removed => 1
 }
=cut
sub handle_remove
{
	my ($db, $jreq) = @_;
	my $mine_id = $jreq->{F_id} or return('ERR_ARGNO_ID');

	my $where = {F_id => $mine_id};
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


# 按 id 查询单行，直接返回记录 hashref ，不存在时返回 undef
sub query_single
{
	my ($db, $id) = @_;
	my $where = {F_id => $id};
	my ($qry_err, $qry_res) = handle_query($db, {where => $where});
	if ($qry_err || !$qry_res->{records}) {
		return undef;
	}
	return $qry_res->{records}->[0];
}

=head1 config table operate
=cut

=markdown handle_query_config()
	查询配置
	类似 handle_query ,但省略分页
=cut
sub handle_query_config
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	my $fields = $jreq->{fields} // \@FIELD_CONFIG;
	my $where = $jreq->{where};

	my $records = $db->Query($fields, $where);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
	$jres->{records} = $records;

	return ($error, $jres);
}

=markdown handle_create_config()
	创建配置
=cut
sub handle_create_config
{
	return handle_create(@_);
}

=markdown handle_modify_config()
	修改配置
=cut
sub handle_modify_config
{
	return handle_modify(@_);
}

=markdown handle_remove_config()
	删除配置
	req = { id }
	res = { F_id, affected }
=cut
sub handle_remove_config
{
	return handle_remove(@_);
}
