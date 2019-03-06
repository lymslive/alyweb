#! /usr/bin/env perl
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use ForkCGI;
use view::manager;

my $USER = 'lymslive';
my $PASS = '190405';

my $LOG = WebLog::instance();
##-- MAIN --##
sub main
{
	my @argv = @_;

	my $st = {};
	$st->{PARAM} = ForkCGI::Param();
	$st->{COOKIE} = ForkCGI::Cookie();
	check_login($st);
	tool_list($st);
	my $html = view::manager->new();
	return $html->runout($st, $LOG);
}

##-- SUBS --##

sub tool_list
{
	my ($st) = @_;
	$st->{list} = {
		PullNotebook => {
			desc => '更新日记本',
			cgi => 'gitpull.cgi?path=notebook',
		},
		PullVimllearn => {
			desc => '更新书籍《VimL语言指北录》',
			cgi => 'gitpull.cgi?path=book/vimllearn',
		},
		PullAlymWeb => {
			desc => '更新网站内容',
			cgi=>'gitpull.cgi',
		},
	};
}

sub check_login
{
	my ($st) = @_;
	my $param = $st->{PARAM};
	my $user = $param->{uid};
	my $pass = $param->{key};

	if (!$user || $user ne $USER) {
		return elog('用户名不对');
	}
	if (!$pass || $pass ne $PASS) {
		return elog('密码不对');
	}

	$st->{logined} = 1;
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__
