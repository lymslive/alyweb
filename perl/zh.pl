#!/usr/local/bin/perl

print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head><title>Perl Environment Variables</title></head>
<meta charset="utf-8">
<body>
<h1>FCGI 不支持中文吗？</h1>
<p> 加上 charset utf8 就可以啦</p>
<h1> 以下是当前请求中，pl 脚本获得的环境变量</h1>
EndOfHTML

foreach $key (sort(keys %ENV)) {
  print "$key = $ENV{$key}<br>\n";
}

print "</body></html>";

