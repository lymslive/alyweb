#! /usr/bin/env perl
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use FamilyAPI;
require 'view/detail.pl';

use URI::Escape;
use Encode;

my $DEBUG = 1;
my $REG_ID = qr/^\d+$/;

##-- MAIN --##
sub main
{
	my @argv = @_;
	my $param = input_param(@argv);
	my $debug = $param->{debug} // $DEBUG;

	# 当前需要操作的行
	my $operate_result = '';
	if ($param->{operate} && $param->{operate} eq 'modify') {
		$operate_result = modify_row($param);
	}

	my $id = $param->{mine_id};
	my $detail = query_detail($id);
	$detail->{operate_result} = $operate_result;
	my $Body = HTPL::generate($detail);
	if ($debug) {
		$Body .= "\n" . debug_log($debug);
	}

	return HTPL::response('', $Body);
}

##-- SUBS --##
# 获取 GET 与 POST 参数，转为 hash ，保留空值
# 返回 hashref
sub input_param
{
	# 在终端测试时，可提供命令行参数
	# 模拟 web cgi 时，GET 从环境变量获取，POST 从标准输入获取
	my ($var) = @_;
	
	my ($query, %query, $post, %post);
	$query = $ENV{QUERY_STRING} // '';
	{
		local $/ = undef;
		$post = <>;
	}
	wlog("query: $query");
	wlog("post: $post");
	%query = map { /(\w+)=(\S+)/ ? ($1 => uri_unescape($2)) : ()} split(/&/, $query) if $query;
	%post = map { /(\w+)=(\S+)/ ? ($1 => uri_unescape($2)) : ()} split(/&/, $post) if $post;

	# 统一合并为 param 
	my %param = (%query, %post);
	foreach my $key (sort keys %param) {
		$param{$key} = decode('utf8', $param{$key});
		wlog("请求参数 param: $key=" . $param{$key});
	}

	return \%param;
}

# 查询详情
# 输入：id
# 输出：{} ，除了本行记录，再联表查询祖先继承关系与所有子女
sub query_detail
{
	my ($id) = @_;
	
	my $detail = {};
	my $req = { api => "query", data => { filter => { id => $id}}};
	my $res = FamilyAPI::handle_request($req);
	my $data = $res->{data} or return {};
	my $row = $data->[0] or return {};

	$detail->{id} = $id;
	$detail->{name} = $row->{F_name};
	$detail->{sex} = $row->{F_sex};
	$detail->{level} = $row->{F_level};
	$detail->{birthday} = $row->{F_birthday};
	$detail->{deathday} = $row->{F_deathday};

	if ($row->{F_partner}) {
		my $partner = query_base($row->{F_partner});
		$detail->{partner} = $partner->{name};
	}

	# 直系后代须查父母
	if ($detail->{level} > 1) {
		my $root = [];
		my $root_id = 0;
		if ($row->{F_father}) {
			my $parent = query_base($row->{F_father});
			$detail->{father} = $parent->{name};
			if ($parent->{level} > 0) {
				push(@$root, {id => $row->{F_father}, name => $parent->{name}, sex => 1});
				$root_id = $row->{F_father};
			}
		}
		if ($row->{F_mother}) {
			my $parent = query_base($row->{F_mother});
			$detail->{mother} = $parent->{name};
			if ($parent->{level} > 0) {
				push(@$root, {id => $row->{F_mother}, name => $parent->{name}, sex => 0});
				$root_id = $row->{F_mother};
			}
		}

		if (!$root_id) {
			wlog("查询父/母失败");
			return {error => "查询父/母失败"};
		}

		# 继续往上查祖父……
		for (my $level = $row->{F_level} - 1; $level > 1; $level--) {
			wlog("query root_id: $root_id; level $level");
			my $parent = select_parent($root_id);
			last unless %$parent;
			push(@$root, $parent);
			$root_id = $parent->{id};
		}

		$detail->{root} = $root;
	}

	# 查询子女
	$detail->{child} = select_child($detail->{id}, $detail->{sex});

	return $detail;
}

# 由 id 查询基本的 name sex level
sub query_base
{
	my ($id) = @_;
	my $base = {};
	my $fields = ['F_name', 'F_level', 'F_sex'];
	my $req = { api => "query", data => { filter => { id => $id}, fields => $fields}};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('查询数据失败：' . $res->{errmsg});
		return {};
	}
	my $data = $res->{data} or return {};
	my $row = $data->[0] or return {};
	$base->{id} = $id;
	$base->{name} = $row->{F_name};
	$base->{level} = $row->{F_level};
	$base->{sex} = $row->{F_sex};
	return $base;
}

# 选出一个继承父母，level > 0 的
# 返回父/母的信息 {id , name, sex}
sub select_parent
{
	my ($id) = @_;
	
	my $req = { api => "query", data => { filter => { id => $id}, fields => ['F_father', 'F_mother', 'F_sex']}};
	my $res = FamilyAPI::handle_request($req);
	my $data = $res->{data} or return {};
	my $row = $data->[0] or return {};
	if ($row->{F_father}) {
		my $parent = query_base($row->{F_father});
		if ($parent->{level} > 0) {
			return {id => $row->{F_father}, name => $parent->{name}, sex => 1};
		}
	}
	elsif ($row->{F_mother}) {
		my $parent = query_base($row->{F_mother});
		if ($parent->{level} > 0) {
			return {id => $row->{F_mother}, name => $parent->{name}, sex => 0};
		}
	}

	wlog('查询父/母失败');
	return {};
}

# 查询所有子女
# 输入：自己的 id sex
# 输出：数组 [{id name sex}]
sub select_child
{
	my ($id, $sex) = @_;
	wlog("id: $id; sex: $sex");
	return [] unless $id;
	
	my @fields = qw[F_id F_name F_sex];
	my $filter = {};
	if ($sex == 1) {
		$filter->{father} = $id;
	}
	elsif ($sex == 0) {
		$filter->{mother} = $id;
	}
	else {
		return [];
	}

	my $req = { api => "query", data => { filter => $filter, fields => \@fields}};
	my $res = FamilyAPI::handle_request($req);
	my $data = $res->{data} or return [];

	# 复制并转化出数据
	my @child;
	foreach my $row (@$data) {
		push(@child, {id => $row->{F_id}, name => $row->{F_name}, sex => $row->{F_sex}});
	}
	
	return \@child;
}

sub modify_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $msg = '修改成功';
	my $req_data = param2api($param);
	if (!$req_data->{id}) {
		$msg = '需要输入被修改成员的id';
		wlog($msg);
		return $msg;
	}

	my $req = { api => "modify", data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		$msg = '修改数据失败：' . $res->{errmsg};
		wlog($msg);
		return $msg;
	}

	return $msg;
}

sub debug_log
{
	my ($debug) = @_;
	my $display = ($debug > 0) ? 'inline' : 'none';
	my $log = WebLog::buff_as_web();
	my $html = <<EndOfHTML;
<div id="debug_log" style="display:$display">
	<hr>
	$log
</div>
EndOfHTML
	return $html;
}

# 将网络参数转为 api 参数
sub param2api
{
	my ($param) = @_;
	
	my $data = {};
	$data->{id} = $param->{mine_id} if $param->{mine_id};
	$data->{name} = $param->{mine_name} if $param->{mine_name};
	$data->{sex} = $param->{sex} if defined($param->{sex});
	$data->{birthday} = $param->{birthday} if $param->{birthday};
	$data->{deathday} = $param->{deathday} if $param->{deathday};
	if ($param->{father}) {
		if ($param->{father} =~ $REG_ID) {
			$data->{father_id} = $param->{father};
		}
		else {
			$data->{father_name} = $param->{father};
		}
	}
	if ($param->{mother}) {
		if ($param->{mother} =~ $REG_ID) {
			$data->{mother_id} = $param->{mother};
		}
		else {
			$data->{mother_name} = $param->{mother};
		}
	}
	if ($param->{partner}) {
		if ($param->{partner} =~ $REG_ID) {
			$data->{partner_id} = $param->{partner};
		}
		else {
			$data->{partner_name} = $param->{partner};
		}
	}

	return $data;
}

##-- END --##
&main(@ARGV) unless defined caller;

if (!$ENV{REMOTE_ADDR}) {
	my $log = WebLog::buff_as_web();
	print $log . "\n";

}

1;
__END__
