#! /usr/bin/env perl
# package japi;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use FamilyAPI;
use WebLog;
use JSON;

my $post = '';
{
	local $/ = undef;
	$post = <>;
}

wlog($post);
my $json_req = decode_json($post);
my $json_res = FamilyAPI::handle_request($json_req);
my $string_res = encode_json($json_res);
wlog($string_res);

print "Content-type:text/json\n\n";
print $string_res;

# 不是从网页 CGI ，认为从终端运行
if (!$ENV{REMOTE_ADDR}) {
	print "\n"; # 将标准输出刷出，再向标准错误输出
	print STDERR "--" x 20;
	print STDERR "\n";
	print STDERR "consol log:\n";
	WebLog::buff_to_std();
}

1;
__END__
