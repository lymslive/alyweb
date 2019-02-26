#! /usr/bin/env perl
# package view_table;
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use FamilyAPI;
require 'tpl/view_table.pl';

use URI::Escape;

# 先取出 id=>name 映射，能读入全表时无误
my $mapid = {};
my $DEBUG = 1;
my $QUICK = shift // 0;

##-- MAIN --##
sub main
{
	my @argv = @_;
	my $param = input_param(@argv);

	# 当前需要操作的行
	my $hot_row = {};
	if ($param && $param->{operate} eq 'remove') {
		$hot_row->{remove} = remove_row($param);
	}
	if ($param && $param->{operate} eq 'modify') {
		$hot_row->{modify} = modify_row($param);
	}
	if ($param && $param->{operate} eq 'create') {
		$hot_row->{create} = create_row($param);
	}

	my $Title = '谭氏家谱网';
	my $BodyH1 = '谭氏年浪翁子嗣家谱表';

	return if $QUICK;
	my $Table = inner_table($hot_row, $param);
	my $Body = HTPL::body($BodyH1, $Table);
	if ($ENV{REMOTE_ADDR} && ($DEBUG || $param->{debug})) {
		$Body .= "\n" . debug_log();
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
	%query = map {$1 => uri_unescape($2) if /(\w+)=(\S*)/} split(/&/, $query) if $query;
	%post = map {$1 => uri_unescape($2) if /(\w+)=(\S*)/} split(/&/, $post) if $post;

	# 统一合并为 param 
	# my %param = (%query, %post); # 直接拼合，undef 可能乱
	my %param = ();
	foreach my $key (sort keys %query) {
		wlog("query: $key=" . $query{$key});
		$param{$key} = $query{$key};
	}
	foreach my $key (sort keys %post) {
		wlog("post: $key=" . $post{$key});
		$param{$key} = $post{$key};
	}

	return \%param;
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

	# my $mapid = {};
	foreach my $row (@$data) {
		$mapid->{$row->{F_id}} = $row->{F_name};
	}

	my $th = HTPL::table_head();
	my @html = ($th);
	foreach my $row (@$data) {
		my $row_data = unpack_row($row);
		push @html, HTPL::table_row($row_data, 1);
	}

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

sub unpack_row
{
	my ($row) = @_;
	
	my $null = '--';
	my $id = $row->{F_id} // $null;
	my $name = $row->{F_name} // $null;
	my $sex = $row->{F_sex} // $null;
	$sex == 1 ? $sex = '男' : $sex = '女';
	my $level = $row->{F_level} // $null;
	my $father = $row->{F_father} // $null;
	if ($row->{F_level} > 0 && $mapid->{$father}) {
		$father = $mapid->{$father};
	}
	my $mother = $row->{F_mother} // $null;
	if ($row->{F_level} > 0 && $mapid->{$mother}) {
		$mother = $mapid->{$mother};
	}
	my $partner = $row->{F_partner} // $null;
	if ($row->{F_level} > 0 && $mapid->{$partner}) {
		$partner = $mapid->{$partner};
	}
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

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚删除的行</td>
</tr>
EndOfHTML
	$html .= HTLP::table_row($row_data, 0);
	return $html;
}

sub modify_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $id = $param->{id} or return '';

	my $req = { api => "modify", data => { id => $id}};
	my $res = FamilyAPI::handle_request($req);

	$req = { api => "query", data => { filter => { id => $id}}};
	$res = FamilyAPI::handle_request($req);

	my $data = $res->{data} or return '';
	my $row = $data->[0] or return '';
	my $row_data = unpack_row($row);

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚修改的行</td>
</tr>
EndOfHTML
	$html .= HTLP::table_row($row_data, 0);
	return $html;
}

sub create_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $id = $param->{id} or return '';
	my $req = { api => "create", data => { id => $id}};
	my $res = FamilyAPI::handle_request($req);

	$req = { api => "query", data => { filter => { id => $id}}};
	$res = FamilyAPI::handle_request($req);

	my $data = $res->{data} or return '';
	my $row = $data->[0] or return '';
	my $row_data = unpack_row($row);

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚添加的行</td>
</tr>
EndOfHTML
	$html .= HTLP::table_row($row_data, 0);
	return $html;
}

sub debug_log
{
	my ($var) = @_;
	my $log = WebLog::buff_as_web();
	my $html = <<EndOfHTML;
<div id="debug_log">
	<hr>
	$log
</div>
EndOfHTML
	return $html;
}

##-- END --##
&main(@ARGV) unless defined caller;

if ($QUICK && !$ENV{REMOTE_ADDR}) {
	my $log = WebLog::buff_as_web();
	print $log . "\n";

}

1;
__END__
