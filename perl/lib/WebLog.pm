#! /usr/bin/env perl
use utf8;
package WebLog;

use Exporter 'import';
@EXPORT = qw(wlog elog);

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

## Class API
sub new
{
	my ($class) = @_;
	my $self = {};
	
	$self->{buff} = [];
	$self->{kuff} = {};

	bless $self, $class;
	return $self;
}

sub open
{
	my ($class, $file) = @_;
	my $self = new($class);
	unless (open($self->{FH}, '>>', $file)) {
		warn "cannot open $file $!";
		$self->{FH} = undef;
	}
	
	return $self;
}

sub close
{
	my ($self) = @_;
	if ($self->{FH}) {
		close($self->{FH});
	}
	$self->{buff} = [];
	$self->{kuff} = {};
}

my $INSTANCE;
sub instance
{
	my ($var) = @_;
	if (!$INSTANCE) {
		$INSTANCE = __PACKAGE__->new();
	}
	return $INSTANCE;
}

sub addlog
{
	my ($self, $msg) = @_;
	push(@{$self->{buff}}, $msg) unless $self->{nobuff};
	if ($self->{to_std}) {
		print STDERR "$msg\n";
	}
	if ($self->{FH}) {
		my $fh = $self->{FH};
		print $fh "$msg\n";
	}
}

sub output_std
{
	my ($self) = @_;
	foreach my $logstr (@{$self->{buff}}) {
		print STDERR "$logstr\n";
	}
}

sub to_string
{
	my ($self, $br) = @_;
	$br //= '';
	return join($br, @{$self->{buff}});
}

sub to_webline
{
	my ($self) = @_;
	return $self->to_string("<br>\n");
}

## Function API

=sub wlog()
  通用记录日志函数，导出函数，利用模块的默认单例对象记录日志，
  内部缓存日志，根据配置打对终端或文件。
  日志格式：[file:line] (sub) | msg
  入参：$msg 字符串，$cfg 可选配置。
    cfg.deep 额外回退栈数，影响输入的文件名，函数名
  出参：始终返回 1
=cut
sub wlog
{
	return 1 if $disable;

	my ($msg, $cfg) = @_;

	my $deep = 0;
	if ($cfg && $cfg->{deep}) {
		$deep += $cfg->{deep};
	}

	# 获取函数名要多退一层栈
	my ($package, $filename, $line, $subroutine_) = caller($deep);
	my ($package_, $filename_, $line_, $subroutine) = caller($deep + 1);

	$filename = basename($filename);
	# caller 获取的函数名含包名前缀，去掉
	$subroutine =~ s/^.*:://g;
	my $logstr = "[$filename:$line] ($subroutine) | $msg";

	instance()->addlog($logstr);
	return 1;

	if ($to_std) {
		print STDERR "$logstr\n";
	}

	push @in_buff, $logstr;
	1; # always true
}

=sub elog()
  记录日志，并返回 {error => $msg}
=cut
sub elog
{
	my ($msg) = @_;
	wlog($msg, {deep => 1});
	return {error => $msg};
}
1;
