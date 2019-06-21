#! /usr/bin/env perl
use utf8;
package WebLog;

use Exporter 'import';
@EXPORT = qw(wlog elog);

use strict;
use warnings;
use File::Basename;

our $ONLY_STD = 0;
our $TIE_STD = 0;
our $DISABLE = 0;
our $LOGFILE = '/tmp/perl-cgi.log';

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

# also new a object with logfile
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

sub addlog
{
	my ($self, $msg) = @_;
	if ($self->{TIE_STD}) {
		print STDERR "$msg\n";
	}
	if ($self->{FH}) {
		my $fh = $self->{FH};
		print $fh "$msg\n";
	}
	push(@{$self->{buff}}, $msg) unless $self->{nobuff};
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
	$br //= "\n";
	return join($br, @{$self->{buff}});
}

sub to_webline
{
	my ($self) = @_;
	return $self->to_string("<br>\n");
}

my $INSTANCE;
sub instance
{
	if (!$INSTANCE) {
		if ($ENV{REMOTE_ADDR}) {
			$INSTANCE = __PACKAGE__->open($LOGFILE);
		}
		$INSTANCE = __PACKAGE__->new();
	}
	return $INSTANCE;
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
	return 1 if $DISABLE;

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

	if ($ONLY_STD) {
		print STDERR "$logstr\n";
	}
	else {
		instance()->addlog($logstr);
	}

	return 1;
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

sub std
{
	$ONLY_STD = 1;
}

1;
