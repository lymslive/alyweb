#! /usr/bin/env perl
# package view_table;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use FamilyAPI;
require 'tpl/view_table.pl';

use URI::Escape;

##-- MAIN --##
sub main
{
	my @argv = @_;

	# 获取 GET 与 POST 参数，转为 hash
	my ($query, %query, $post, %post);
	$query = $ENV{QUERY_STRING};
	%query = map {$1 => uri_unescape($2) if /(\w+)=(\S+)/} split(/&/, $query) if $query;
	{
		local $/ = undef;
		$post = <>;
	}
	%post = map {$1 => uri_unescape($2) if /(\w+)=(\S+)/} split(/&/, $post) if $post;
}

##-- SUBS --##

sub inner_table
{
	my ($var) = @_;
	my $req = { api => 'query', data => { all => 1} };
	my $res = FamilyAPI::handle_request($req);
	if (!$res || $res->{error}) {
		return '';
	}
	my $data = $res->{data};

	my $th = HTML::table_head;
	my @html = ($th);
	foreach my $row (@$data) {
		push @html, row_table($row);
	}
	push @html, $th;
}

sub row_table
{
	my ($row) = @_;
	# todo
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__
