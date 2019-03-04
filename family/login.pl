#! /usr/bin/env perl
# package login;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use ForkCGI;
use FamilyAPI;
use view::login;

my $DEBUG = 0;
$DEBUG = 1 if $ENV{SCRIPT_NAME} =~ m/\.pl$/;
my $LOG = WebLog::instance();

##-- MAIN --##
sub main
{
	my @argv = @_;
	my $param = ForkCGI::Param(@argv);
	my $debug = $param->{debug} // $DEBUG;
	$LOG->{debug} = $debug;

	my $data = {login => 0};
	if ($param->{uid}) {
		$data = check_login($param);
	}

	my $html = view::login->new();
	return $html->runout($data, $LOG);
}

##-- SUBS --##

sub check_login
{
	my ($param) = @_;
	my $uid = $param->{uid};

	my $byid = 0;
	my $filter = {};
	if ($uid =~ /^\d+$/) {
		$filter->{id} = $uid;
		$byid = 1;
	}
	else {
		$filter->{name} = $uid;
	}

	my $fields = ['F_id', 'F_name', 'F_level', 'F_sex'];
	my $req = { api => "query", data => { filter => $filter, fields => $fields}};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('查询数据失败：' . $res->{errmsg});
		return {error => '查询数据失败：' . $res->{errmsg}};
	}
	my $row = $data->[0] or return {error => '不存在登陆名'};

	$uid = $row->{F_id};
	my $uname = $row->{F_name};
	return {uid => $uid, uname => $uname, login => 1};
}

##-- END --##
&main(@ARGV) unless defined caller;

if (ForkCGI::TermTest()) {
	$LOG->output_std();
}

1;
__END__
