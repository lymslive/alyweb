#! /usr/bin/env perl
# package view_table;
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use ForkCGI;
use FamilyAPI;
use FamilyUtil;
require 'view/table.pl';

my $DEBUG = 0;
my $LOG = WebLog::instance();
wlog("SCRIPT_NAME: $ENV{SCRIPT_NAME}");
$DEBUG = 1 if $ENV{SCRIPT_NAME} =~ m/\.pl$/;

##-- MAIN --##
sub main
{
	my @argv = @_;
	my $param = ForkCGI::Param(@argv);
	my $debug = $param->{debug} // $DEBUG;
	$LOG->{debug} = $debug;

	my $data = deal($param);
	my $html = HTPL->new();
	return $html->runout($data, $LOG);
}

=markdown deal()
	准备数据
返回：hashref{}
	error => 数据处理出错信息，抑制剩余字段
	rows => 检索的数据行
	removed, modified, created => 增删改操作结构
		error => 操作出错信息
		id => 
		queried => 操作前后重新检索过
		row => 被操作的行
=cut
sub deal
{
	my ($param) = @_;
	my $data = {};

	# 当前需要操作的行
	if ($param->{operate} && $param->{operate} eq 'remove') {
		$data->{removed} = remove_row($param);
	}
	if ($param->{operate} && $param->{operate} eq 'modify') {
		$data->{modified} = modify_row($param);
	}
	if ($param->{operate} && $param->{operate} eq 'create') {
		$data->{created} = create_row($param);
	}

	my $req = { api => 'query', data => { all => 1} };
	my $res = FamilyAPI::handle_request($req);
	if (!$res || $res->{error}) {
		return {error => "查询数据失败：$res->{error}"};
	}
	my $res_data = $res->{data};

	# id=>name 映射
	my $mapid = {};
	wlog('顺便缓存 id=>name 映射表');
	foreach my $row (@$res_data) {
		$mapid->{$row->{F_id}} = $row->{F_name};
	}

	$data->{rows} = $res_data;
	foreach my $row (@$res_data) {
		# 加工检索行，原位添加父母配偶的名字
		append_name($mapid, $row);

		# 匹配刚修改的行
		if ($data->{modified}
			&& $data->{modified}->{id}
			&& $data->{modified}->{id} == $row->{F_id}) {
			wlog("匹配到修改行：" . $data->{modified}->{id});
			$data->{modified}->{row} = $row;
			$data->{modified}->{queried} = 1;
		}
		if ($data->{created}
			&& $data->{created}->{id}
			&& $data->{created}->{id} == $row->{F_id}) {
			wlog("匹配到增加行：" . $data->{created}->{id});
			$data->{created}->{row} = $row;
			$data->{created}->{queried} = 1;
		}
	}

	# 未匹配刚修改的行
	if ($data->{modified}
		&& $data->{modified}->{id}
		&& !$data->{modified}->{queried}) {
		my $row = query_single($data->{modified}->{id});
		if (!$row->{error}) {
			append_name($mapid, $row);
			$data->{modified}->{row} = $row;
			$data->{modified}->{queried} = 1;
		}
		else {
			$data->{modified}->{error} = $row->{error};
		}
	}
	if ($data->{created}
		&& $data->{created}->{id}
		&& !$data->{created}->{queried}) {
		my $row = query_single($data->{created}->{id});
		if (!$row->{error}) {
			append_name($mapid, $row);
			$data->{created}->{row} = $row;
			$data->{created}->{queried} = 1;
		}
		else {
			$data->{created}->{error} = $row->{error};
		}
	}

	return $data;
}

sub append_name
{
	my ($mapid, $row) = @_;
	
	if ($row->{F_father}) {
		if ($mapid->{$row->{F_father}}) {
			$row->{father_name} = $mapid->{$row->{F_father}};
		}
		else {
			$row->{father_name} = update_mapid($mapid, $row->{F_father});
		}
	}
	if ($row->{F_mother}) {
		if ($mapid->{$row->{F_mother}}) {
			$row->{mother_name} = $mapid->{$row->{F_mother}};
		}
		else {
			$row->{mother_name} = update_mapid($mapid, $row->{F_mother});
		}
	}
	if ($row->{F_partner}) {
		if ($mapid->{$row->{F_partner}}) {
			$row->{partner_name} = $mapid->{$row->{F_partner}};
		}
		else {
			$row->{partner_name} = update_mapid($row->{F_partner});
		}
	}
}

# 更新 mapid 缓存，添加一个 id, 返回对应的 name
sub update_mapid
{
	my ($mapid, $id) = @_;
	
	my $req_data = { filter => {id => $id}, fields => ['F_id', 'F_name']};
	my $req = { api => 'query', data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error}) {
		wlog("检索 $id 失败：$res->{error}");
		return '';
	}
	my $first = $res->{data}->[0];
	$mapid->{$first->{F_id}} = $first->{F_name};
	wlog("更新缓存：$id => $first->{F_name}");
	return $first->{F_name};
}

# 缓存所有 id=>name ，暂未用了
sub cache_mapid
{
	my ($mapid) = @_;
	my $req_data = { all => 1, fields => ['F_id', 'F_name']};
	my $req = { api => 'query', data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	return if $res->{error};
	my $res_data = $res->{data};
	foreach my $row (@$res_data) {
		$mapid->{$row->{F_id}} = $row->{F_name};
	}
	wlog('预缓存 id=>name 映射表');
}
sub id2name
{
	my ($mapid, $id) = @_;
	return $id unless $id > 0;
	return $mapid->{$id} if defined($mapid->{$id});
	cache_mapid();
	return $mapid->{$id};
}

# 查询一行数据，返回 {F_字段}，如果出错，返回 {error}
sub query_single
{
	my ($id) = @_;
	
	my $req = { api => "query", data => { filter => { id => $id}}};
	my $res = FamilyAPI::handle_request($req);

	if (!$res || $res->{error} || !$res->{data}) {
		my $msg = "检索 $id 失败：$res->{error}";
		wlog($msg);
		return {error => $msg};
	}

	my $row = $res->{data}->[0] or return {error => "检索 $id 失败"};
	return $row;
}

# 增删改操作，返回 {} 字段如下：
# error => 操作出错，不再有其他字段
# id =>
# queried => 已检索过
# row => 数据行
sub remove_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $id = $param->{id} or return {error => '未指定删除 id'};
	my $row = query_single($id);
	if ($row->{error}) {
		return $row;
	}

	my $removed = {row => $row, queried => 1, id => $id};

	my $req = { api => "remove", data => { id => $id}};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		my $msg = '删除数据失败：' . $res->{errmsg};
		wlog($msg);
		return {error => $msg};
	}

	return $removed;
}

sub modify_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $req_data = FamilyUtil::Param2api($param);
	if (!$req_data->{id}) {
		wlog('需要输入被修改成员的id');
		return {error => '需要输入被修改成员的编号id'};
	}

	my $req = { api => "modify", data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('修改数据失败：' . $res->{errmsg});
		return { error => '修改数据失败：' . $res->{errmsg}};
	}

	return {queried => 0, id => $req_data->{id}};
}

sub create_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $req_data = FamilyUtil::Param2api($param);
	if (!$req_data->{name}) {
		wlog('需要输入新成员的姓名');
		return {error => '需要输入新成员的姓名'};
	}

	wlog("插入新数据");
	my $req = { api => "create", data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('插入数据失败：' . $res->{errmsg});
		return {error => '插入数据失败：' . $res->{errmsg}};
	}

	my $newid = $res->{data}->{id};
	wlog("新增成员ID: $newid");
	return {queried => 0, id => $newid};
}

##-- END --##
&main(@ARGV) unless defined caller;

if (ForkCGI::TermTest()) {
	$LOG->output_std();
}

1;
__END__
