#! /usr/bin/env perl
package AppCGI;
use parent 'ForkCGI';

use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use view::manager;

my $USER = 'lymslive';
my $PASS = '190405';

sub new
{
	my $class = shift;
	return $class->SUPER::new(@_);
}

##-- METHOD --##

sub work
{
	my $self = shift;
	$self->check_login();
	$self->tool_list();
}

sub tool_list
{
	my $self = shift;
	$self->{list} = {
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
	return $self;
}

sub check_login
{
	my $self = shift;
	my $param = $self->{PARAM};
	my $user = $param->{uid};
	my $pass = $param->{key};

	if (!$user || $user ne $USER) {
		return $self->error('用户名不对');
	}
	if (!$pass || $pass ne $PASS) {
		return $self->error('密码不对');
	}

	$self->{logined} = 1;
	return $self;
}

##-- MAIN --##
sub main
{
	my @argv = @_;

	my $cgi = __PACKAGE__->new();
	$cgi->work();
	my $html = view::manager->new();
	return $html->runout($cgi);
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__
