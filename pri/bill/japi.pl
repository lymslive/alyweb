#! /usr/bin/env perl
# package japi;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use BillAPI;
use WebLog;
use JSON;

##-- MAIN --##
sub main
{
	# my @argv = @_;

	# 读入 post 请求内容
	my $post = '';
	{
		local $/ = undef;
		$post = <>;
	}
	if (!$post) {
		return err_output("Empty post requset!");
	}

	wlog("Request post: " . $post);
	my $json_req = eval { decode_json($post) };
	unless ($json_req) {
		return err_output("Fail to decode post json: " . $@);
	}
	
	my $json_res = BillAPI::handle_request($json_req);
	my $string_res = eval { encode_json($json_res) };
	unless ($json_req) {
		return err_output("Fail to encode response to json: " . $@);
	}

	# 输出响应
	wlog("Response json: " . $string_res);
	print "Content-type:application/json\n\n";
	print $string_res;

	# 不是从网页 CGI ，认为从终端运行
	if (!$ENV{REMOTE_ADDR}) {
		on_console();
	}
}

##-- SUBS --##

# 异常错误输出响应
sub err_output
{
	my ($errmsg) = @_;
	wlog($errmsg);
	my $json_res = {error => -1, errmsg => $errmsg};
	my $string_res = encode_json($json_res);
	print "Content-type:application/json\n\n";
	print $string_res;
}

# 额外向终端输出日志
sub on_console
{
	# 先将标准输出刷出，再向标准错误输出
	print "\n"; 
	print STDERR "--" x 20;
	print STDERR "\n";
	print STDERR "console log:\n";
	WebLog::instance()->output_std();
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__
