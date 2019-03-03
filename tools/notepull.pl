#! /usr/bin/env perl
use strict;
use warnings;

# 修改运行用户名为 lymslive （用于执行 git）
use POSIX qw(setuid);

print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head><title>Notebook Update</title></head>
<body>
<h1>Notebook Update</h1>
EndOfHTML

my $notebook = '/usr/local/nginx/html/notebook/';
chdir $notebook;
print "\$ chdir $notebook<br>";

# 测试平凡命令
my $cmd = 'ls -l';
print "\$ $cmd<br>\n";
my $output = qx($cmd);
print "<pre>\n";
print "$output<br>\n";
print "</pre>\n";

$cmd = 'pwd';
print "\$ $cmd<br>\n";
$output = qx($cmd);
print "$output<br>\n";

$cmd = 'whoami';
print "\$ $cmd<br>\n";
$output = qx($cmd);
print "$output<br>\n";

setuid(1000);

$cmd = 'whoami';
print "\$ $cmd<br>\n";
$output = qx($cmd);
print "$output<br>\n";

# 更新 git pull 命令
$cmd = '/usr/bin/git pull 2>&1';
print "\$ $cmd<br>\n";
$output = qx($cmd);
print "$output<br>\n";

print "</body></html>";

