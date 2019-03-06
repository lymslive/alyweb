#! /usr/bin/env perl
# package gitpull;
# 代码更新，从网页 cgi 运行
use strict;
use warnings;

use ForkCGI;
my $param = ForkCGI::Param();
my $path = $param->{path} // '';

my $root = $ENV{DOCUMENT_ROOT };
if (!$path) {
	$path = $root;
}
elsif ($path !~ m|^/|) {
	$path = "$root/$path";
}

print "Content-type:text/html\n\n";
print <<HTML;
<html><head><title>Git Pull Update</title></head>
<body>
<h1>代码更新 Git Pull</h1>
HTML

chdir $path;
print "\$ cd $path<br>";

my $cmd = 'ls -l';
print "\$ $cmd<br>\n";
my $output = qx($cmd);
print "<pre>\n";
print "$output<br>\n";
print "</pre>\n";

# 更新 git pull 命令
$cmd = '/usr/bin/git pull 2>&1';
print "\$ $cmd<br>\n";
$output = qx($cmd);
print "$output<br>\n";

print "</body></html>";
