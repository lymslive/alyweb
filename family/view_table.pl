#! /usr/bin/env perl
# package view_table;
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use FamilyAPI;
require 'view/table.pl';

use URI::Escape;
use Encode;

# 先取出 id=>name 映射，能读入全表时无误
my $mapid = {};
my $DEBUG = 0;
my $QUICK = shift // 0;
my $REG_ID = qr/^\d+$/;

##-- MAIN --##
sub main
{
	my @argv = @_;
	my $param = input_param(@argv);
	my $debug = $param->{debug} // $DEBUG;
	HTPL::show_operate($debug);

	# 当前需要操作的行
	my $hot_row = {};
	if ($param->{operate} && $param->{operate} eq 'remove') {
		$hot_row->{remove} = remove_row($param);
	}
	if ($param->{operate} && $param->{operate} eq 'modify') {
		$hot_row->{modify} = modify_row($param);
	}
	if ($param->{operate} && $param->{operate} eq 'create') {
		$hot_row->{create} = create_row($param);
	}

	my $Title = '谭氏家谱网';
	my $BodyH1 = '谭氏年浪翁子嗣家谱表（测试版）';

	return if $QUICK;
	my $Table = inner_table($hot_row, $param);
	my $Body = HTPL::body($BodyH1, $Table);
	if ($debug) {
		$Body .= "\n" . debug_log($debug);
	}

	return HTPL::response($Title, $Body);
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
	# %query = map {$1 => uri_unescape($2) if /(\w+)=(\S*)/} split(/&/, $query) if $query;
	# %post = map {$1 => uri_unescape($2) if /(\w+)=(\S*)/} split(/&/, $post) if $post;
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

sub cache_mapid
{
	my ($var) = @_;
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

sub inner_table
{
	my ($hot_row, $post) = @_;
	my $req = { api => 'query', data => { all => 1} };
	my $res = FamilyAPI::handle_request($req);
	if (!$res || $res->{error}) {
		return '';
	}
	my $data = $res->{data};

	# 未缓存id-name映射时
	if (scalar(%$mapid) < 1) {
		wlog('顺便缓存 id=>name 映射表');
		foreach my $row (@$data) {
			$mapid->{$row->{F_id}} = $row->{F_name};
		}
	}

	my $th = HTPL::table_head();
	my @html = ($th);
	foreach my $row (@$data) {
		my $row_data = unpack_row($row);
		push @html, HTPL::table_row($row_data, 1);
	}

	my $count = scalar(@$data);
	push @html, HTPL::table_sumary($count);

	if ($hot_row) {
		if ($hot_row->{remove}) {
			push @html, $hot_row->{remove};
		}
		if ($hot_row->{modify}) {
			push @html, $hot_row->{modify};
		}
		if ($hot_row->{create}) {
			push @html, $hot_row->{create};
		}
	}

	push @html, HTPL::table_form();
	push @html, $th;

	return join("\n", @html);
}

sub id2name
{
	my ($id) = @_;
	return $id unless $id > 0;
	return $mapid->{$id} if defined($mapid->{$id});
	cache_mapid();
	return $mapid->{$id};
}

sub unpack_row
{
	my ($row) = @_;
	
	my $null = '--';
	my $id = $row->{F_id} // $null;
	my $name = $row->{F_name} // $null;
	my $sex = $row->{F_sex} // $null;
	$sex = ($sex == 1 ? '男' : '女');
	my $level = $row->{F_level} // $null;
	my $father = $row->{F_father} ? id2name($row->{F_father}) : $null;
	my $mother = $row->{F_mother} ? id2name($row->{F_mother}) : $null;
	my $partner = $row->{F_partner} ? id2name($row->{F_partner}) : $null;
	my $birthday = $row->{F_birthday} // $null;
	my $deathday = $row->{F_deathday} // $null;

	return [$id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday];
}

sub remove_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $id = $param->{id} or return '';

	my $req = { api => "query", data => { filter => { id => $id}}};
	my $res = FamilyAPI::handle_request($req);

	my $data = $res->{data} or return '';
	my $row = $data->[0] or return '';
	my $row_data = unpack_row($row);

	$req = { api => "remove", data => { id => $id}};
	$res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('删除数据失败：' . $res->{errmsg});
		return HTPL::operate_error('删除数据失败：' . $res->{errmsg});
	}

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚删除的行</td>
</tr>
EndOfHTML
	$html .= HTPL::table_row($row_data, 0);
	return $html;
}

sub modify_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $req_data = param2api($param);
	if (!$req_data->{id}) {
		wlog('需要输入被修改成员的id');
		return HTPL::operate_error('需要输入被修改成员的编号id');
	}

	my $req = { api => "modify", data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('修改数据失败：' . $res->{errmsg});
		return HTPL::operate_error('修改数据失败：' . $res->{errmsg});
	}

	my $id = $req_data->{id};
	$req = { api => "query", data => { filter => { id => $id}}};
	$res = FamilyAPI::handle_request($req);

	my $data = $res->{data} or return '';
	my $row = $data->[0] or return '';
	my $row_data = unpack_row($row);

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚修改的行：</td>
</tr>
EndOfHTML
	$html .= HTPL::table_row($row_data, 0);
	return $html;
}

sub create_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $req_data = param2api($param);
	if (!$req_data->{name}) {
		wlog('需要输入新成员的姓名');
		return HTPL::operate_error('需要输入新成员的姓名');
	}

	wlog("插入新数据");
	my $req = { api => "create", data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('插入数据失败：' . $res->{errmsg});
		return HTPL::operate_error('插入数据失败：' . $res->{errmsg});
	}

	wlog("重新检索插入数据");
	my $new_id = $res->{data}->{id};
	$req = { api => "query", data => { filter => { id => $new_id}}};
	$res = FamilyAPI::handle_request($req);

	my $res_data = $res->{data} or return '';
	my $row = $res_data->[0] or return '';
	my $row_data = unpack_row($row);

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚添加的行：</td>
</tr>
EndOfHTML
	$html .= HTPL::table_row($row_data, 0);
	return $html;
}

sub debug_log
{
	my ($debug) = @_;
	my $display = ($debug > 0) ? 'inline' : 'none';
	my $log = WebLog::buff_as_web();
	# $log = decode('utf8', $log);
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

if ($QUICK && !$ENV{REMOTE_ADDR}) {
	my $log = WebLog::buff_as_web();
	print $log . "\n";

}

1;
__END__
