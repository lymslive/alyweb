#! /usr/bin/env perl
package ForkCGI;
use strict;
use warnings;

use URI::Escape;
use Encode;
use WebLog;

# key=val 正则表达式
my $REG_KV = qr/(\w+)=(\S+)/;

=item Param
	获取 GET 与 POST 以及命令行参数，转为 hash 
输入：
	模拟 web cgi 时，GET 从环境变量获取，POST 从标准输入获取；
	在终端测试时，可额外提供命令行参数，也按 key=val 格式。
输出：
	标量环境下返回 hashref，合并所有 {key => val}。
	GET POST 参数值用 URL 与 utf8 解码。
	GET POST 忽略空值，命令行参数的空值默认为 1，
	存在重复键名时，按 ARGV GET POST 优先级覆盖。
	列表环境下返回四个 hashref (\%param, \%POST, \%GET, \%ARGV)
=cut
sub Param
{
	my @argv = @_;

	my ($query, %query, $post, %post);
	$query = $ENV{QUERY_STRING} // '';
	{
		local $/ = undef;
		$post = <STDIN>;
	}
	wlog("query: $query");
	wlog("post: $post");
	%query = map { $_ =~ $REG_KV ? ($1 => uri_unescape($2)) : ()} split(/&/, $query) if $query;
	%post  = map { $_ =~ $REG_KV ? ($1 => uri_unescape($2)) : ()} split(/&/, $post) if $post;

	my %argv = ();
	foreach my $arg (@argv) {
		if ($arg =~ $REG_KV) {
			$argv{$1} = $2;
		}
		else {
			$argv{$arg} = 1;
		}
	}
	
	# 统一合并为 param 
	my %param = (%post, %query, %argv);
	foreach my $key (keys %param) {
		$param{$key} = decode('utf8', $param{$key});
		wlog("param: $key=" . $param{$key});
	}

	if (wantarray) {
		return (\%param, \%post, \%query, \%argv);
	}
	else {
		return \%param;
	}
}

=item Cookie
	获取请求的 Cookies ，返回 hashref 或空 hashref 。
=cut
sub Cookie
{
	my ($var) = @_;
	my $cookie = $ENV{HTTP_COOKIE};
	return {} unless $cookie;
	my %cookie = map {
		$_ =~ $REG_KV ? ($1 => decode('utf8', uri_unescape($2))) : ()
	} split(/;\s*/, $cookie);
	return \%cookie;
}

=item TermTest
	返回是否在终端测试 CGI 脚本。
=cut
sub TermTest
{
	return !$ENV{REMOTE_ADDR};
}

=pod
debug todo:
	命令行参数是是否要 decode utf8 ？
=cut

##-- MAIN --##
sub main
{
	my @argv = @_;
	my $param = Param(@argv);
	WebLog::instance()->output_std();
}

&main(@ARGV) unless defined caller;
1;
__END__
