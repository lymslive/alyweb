#! /usr/bin/env perl
use strict;
use warnings;

$ENV{DOCUMENT_ROOT} = "/usr/local/nginx/html";
$ENV{QUERY_STRING} = shift;
exec "perl blog.pl";

=pod
伪造 fastcgi 传入的必要的环境变量，
在终端的标准输出中测试博客页面输入

	perl test_blog.pl 't=game&n=yyyymmdd_n'

注意多参数时要加引号，否则 & 视为后台运行
=cut
