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
my $html_title = '添加家庭成员：返回';
my $html_body = '';

my $error_msg = 'no error';
handle_request(\%query);

my $raw_post = uri_unescape($post);
my $debug_output = "接收请求：\n$raw_post\n";
$debug_output .= "关键信息：\n姓名：$query{member_name}；父亲：$query{father_name}\n";
$debug_output .= "$error_msg\n" . $FamilyDB::error;

$debug_output =~ s/\n/\n<br>/g;

$html_body .= $debug_output;

response();

##### 子函数 #####
#
sub handle_request
{
	$error_msg = "enter handle_request\n";
	my ($query) = @_;
	if (!$query->{father_name} && !$query->{mother_name} && !$query->{partner_name}) {
		$error_msg = "lack of relation name\n";
		return $FALSE;
	}

	my $dbh = FamilyDB::Connect();
	if (!$dbh) {
		$error_msg = "fail to connect family database\n";
		return $FALSE;
	}

	db_operate($dbh, $query);
	FamilyDB::Disconnect($dbh);
}

sub db_operate
{
	my ($dbh, $query) = @_;
	
	# 查找参考人名
	my $refer_name;
	if ($query->{partner_name}) {
		$refer_name = $query->{partner_name};
	}
	elsif ($query->{father_name}) {
		$refer_name = $query->{father_name};
	}
	elsif ($query->{mother_name}) {
		$refer_name = $query->{mother_name};
	}
	else {
		return $FALSE;
	}

	my $refer_member = FamilyDB::QueryByName($dbh, $refer_name);
	if (!$refer_member || !$refer_member->{F_id}) {
		$error_msg = "fail to query relation name\n";
		return $FALSE;
	}

	# 构建新对象结构
	my $new_member = {};
	$new_member->{F_name} = $query->{member_name};
	$new_member->{F_sex} = $query->{sex};
	if ($query->{partner_name}) {
		$new_member->{F_partner} = $refer_member->{F_id};
		$new_member->{F_level} = 0 - $refer_member->{F_level};
	}
	elsif ($query->{father_name}) {
		$new_member->{F_father} = $refer_member->{F_id};
		$new_member->{F_level} = 1 + $refer_member->{F_level};
	}
	elsif ($query->{mother_name}) {
		$new_member->{F_level} = 1 + $refer_member->{F_level};
	}
	else {
		return $FALSE;
	}

	if ($query->{birthday}) {
		$new_member->{F_birthday} = $query->{birthday};
	}
	if ($query->{deathday}) {
		$new_member->{F_deathday} = $query->{deathday};
	}
	if ($query->{desc}) {
		$new_member->{F_desc} = $query->{desc};
	}

	my $ret = FamilyDB::InsertMember($dbh, $new_member);
	return $ret;
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
