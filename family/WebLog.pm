#! /usr/bin/env perl
use utf8;
package WebLog;

use Exporter 'import';
@EXPORT = qw(wlog);

use strict;
use warnings;
use File::Basename;

our @in_buff = ();
our $to_std = 0;
our $to_file = 0;
our $disable = 0;

sub init
{
	@in_buff = ();
}

sub wlog(@)
{
	return 1 if $disable;

	my $msg = join(" ", @_);

	# 获取函数名要多退一层栈
	my ($package, $filename, $line, $subroutine_) = caller(0);
	my ($package_, $filename_, $line_, $subroutine) = caller(1);

	$filename = basename($filename);
	# caller 获取的函数名含包名前缀，去掉
	$subroutine =~ s/^.*:://g;
	my $logstr = "[$filename:$line] ($subroutine) | $msg";

	if ($to_std) {
		print STDERR "$logstr\n";
	}

	push @in_buff, $logstr;
	1; # always true
}

sub buff_to_std
{
	my ($var) = @_;
	foreach my $logstr (@in_buff) {
		print STDERR "$logstr\n";
	}
	
}

sub buff_to_str
{
	my ($br) = @_;
	$br //= '';
	return join($br, @in_buff);
}

sub buff_as_web
{
	return buff_to_str("<br>\n");
}

1;
