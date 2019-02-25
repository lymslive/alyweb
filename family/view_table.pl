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

##-- MAIN --##
sub main
{
	my @argv = @_;

	# 获取 GET 与 POST 参数，转为 hash
	my ($query, %query, $post, %post);
	$query = $ENV{QUERY_STRING};
	{
		local $/ = undef;
		$post = <>;
	}
	wlog("query: $query");
	wlog("post: $post");
	%query = map {$1 => uri_unescape($2) if /(\w+)=(\S+)/} split(/&/, $query) if $query;
	%post = map {$1 => uri_unescape($2) if /(\w+)=(\S+)/} split(/&/, $post) if $post;

	# 统一合并为 param 
	my %param = (%query, %post);
	foreach my $key (sort keys %param) {
		wlog("param: $key=" . $param{$key});
	}
	

	# 当前需要操作的行
	my $hot_row = {};
	if (%query && $query{action} eq 'remove') {
		$hot_row->{remove} = remove_row(\%query);
	}
	if (%post && $post{action} eq 'modify') {
		$hot_row->{modify} = modify_row(\%post);
	}
	if (%post && $post{action} eq 'create') {
		$hot_row->{create} = create_row(\%post);
	}

	my $Title = '谭氏家谱网';
	my $BodyH1 = '谭氏年浪翁子嗣家谱表';

	my $Table = inner_table($hot_row, \%post);
	my $Body = HTPL::body($BodyH1, $Table);
	if ($query{debug}) {
		$Body .= "\n" . debug_log();
	}

	return HTPL::response($Title, $Body);
}

##-- SUBS --##

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
		push @html, table_row($row);
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

	return ($id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday);
}

sub table_row
{
	my ($row) = @_;
	my ($id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday) = unpack_row($row);

	my $html = <<EndOfHTML;
<tr>
	<td>$id</td>
	<td>$name</td>
	<td>$sex</td>
	<td>$level</td>
	<td>$father</td>
	<td>$mother</td>
	<td>$partner</td>
	<td>$birthday</td>
	<td>$deathday</td>
	<td>修改</td>
	<td>删除</td>
</tr>
EndOfHTML

	return $html;
}

sub remove_row
{
	my ($param) = @_;
	my $id = $param->{id} or return '';

	my $req = { api => query, data => { filter => { id => $id}}};
	my $res = FamilyAPI::handle_request($req);

	my $data = $res->{data} or return '';
	my $row = $data->[0] or return '';
	my ($id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday) = unpack_row($row);

	$req = { api => remove, data => { id => $id}};
	$res = FamilyAPI::handle_request($req);

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚删除的行</td>
</tr>
<tr>
	<td>$id</td>
	<td>$name</td>
	<td>$sex</td>
	<td>$level</td>
	<td>$father</td>
	<td>$mother</td>
	<td>$partner</td>
	<td>$birthday</td>
	<td>$deathday</td>
	<td>--</td>
	<td>--</td>
</tr>
EndOfHTML
	return $html;
}

sub modify_row
{
	my ($param) = @_;

	my $req = { api => modify, data => { id => $id}};
	my $res = FamilyAPI::handle_request($req);

	$req = { api => query, data => { filter => { id => $id}}};
	$res = FamilyAPI::handle_request($req);

	my $data = $res->{data} or return '';
	my $row = $data->[0] or return '';
	my ($id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday) = unpack_row($row);

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚修改的行</td>
</tr>
<tr>
	<td>$id</td>
	<td>$name</td>
	<td>$sex</td>
	<td>$level</td>
	<td>$father</td>
	<td>$mother</td>
	<td>$partner</td>
	<td>$birthday</td>
	<td>$deathday</td>
	<td>--</td>
	<td>--</td>
</tr>
EndOfHTML
	return $html;
}

sub create_row
{
	my ($param) = @_;
	my $req = { api => create, data => { id => $id}};
	my $res = FamilyAPI::handle_request($req);

	$req = { api => query, data => { filter => { id => $id}}};
	$res = FamilyAPI::handle_request($req);

	my $data = $res->{data} or return '';
	my $row = $data->[0] or return '';
	my ($id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday) = unpack_row($row);

	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">刚添加的行</td>
</tr>
<tr>
	<td>$id</td>
	<td>$name</td>
	<td>$sex</td>
	<td>$level</td>
	<td>$father</td>
	<td>$mother</td>
	<td>$partner</td>
	<td>$birthday</td>
	<td>$deathday</td>
	<td>--</td>
	<td>--</td>
</tr>
EndOfHTML
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
1;
__END__
