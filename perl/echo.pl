#!/usr/local/bin/perl

# get 地址
my @get_kyes = qw(REQUEST_URI SCRIPT_FILENAME SCRIPT_NAME QUERY_STRING);
my $get_info = "";
foreach my $key (@get_kyes) {
	$get_info .= "$key = $ENV{$key}<br>\n";
}

# post 数据
my $post = "";
{
	local $/ = undef;
	$post = <STDIN>;
}

# cookie
my $cookie = $ENV{HTTP_COOKIE};

# 环境变量
my $env = "";
foreach $key (sort(keys %ENV)) {
	$env .= "$key = $ENV{$key}<br>\n";
}

########################################

print "Content-type:text/html\n";
print "\n";
print <<EndOfHTML;
<html><head><title>Perl CGI Echo Request</title></head>
<body>
<h1>Perl CGI GET Info</h1>
$get_info
<h1>Perl CGI POST Data</h1>
$post
<h1>Perl CGI COOKIE Data</h1>
$cookie
<h1>Perl Environment Variables</h1>
$env
</body></html>
EndOfHTML
