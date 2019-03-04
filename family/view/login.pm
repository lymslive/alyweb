#! /usr/bin/env perl
package view::login;
use strict;
use warnings;

use parent qw(HTPL);

##-- Class --##

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = '谭氏家谱网-登陆';
	$self->{body} = '';
	$self->{H1} = '登陆';
	bless $self, $class;
	return $self;
}

sub generate
{
	my ($self, $data, $LOG) = @_;
	if ($data->{error}) {
		return on_error($data->{error});
	}

	$self->{body} = '生成内容';

	return 0;
}

##-- TEST MAIN --##
sub main
{
	my @argv = @_;
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__
