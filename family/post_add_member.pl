#! /usr/bin/env perl
# package post_add_member;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use FamilyDB;

use URI::Escape;

my $post = <>;
my %query = map {$1 => uri_unescape($2) if /(\w+)=(\S+)/} split(/&/, $post);

my $FALSE = 0;
my $TRUE = 1;
my $html_title = '添加家庭成员：结果';
my $html_body = '';

my $raw_post = uri_unescape($post);
my $debug_output = "接收请求：\n$raw_post\n";
$debug_output .= "关键信息：\n姓名：$query{member_name}；父亲：$query{father_name}\n";

my $error_msg = '';

$debug_output =~ s/\n/\n<br>/g;

$html_body .= $debug_output;

response();

##### 子函数 #####
#
sub handel_request
{
	my ($query) = @_;
	if (!$query->{father_name} && !$query->{mother_name} && !$query->{partner_name}) {
		return $FALSE;
	}

	my $dbh = FamilyDB::Connect();
	if (!$dbh) {
		$error_msg = "fail to connect family database\n";
		return $FALSE;
	}

	if ($query->{partner_name}) {
		
	}
	elsif ($query->{father_name}) {
	}
	elsif ($query->{mother_name}) {
	}
	else {
		return $FALSE;
	}
}

sub response
{
	# http header
	print "Content-type:text/html\n\n";

	# http content
	print <<EndOfHTML;
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width" />
		<link rel="stylesheet" type="text/css" href="/css/main.css">
		<link rel="stylesheet" type="text/css" href="/css/markdown.css">
		<title> $html_title </title>
	</head>
	<body>
		$html_body
	</body>
</html>
EndOfHTML

	return 0;
}

1;
__END__
