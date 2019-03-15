#! /usr/bin/env perl
# 伪装成 cgi 的方式发送静态 web/app.html
# 作简单的字符串处理，替换 css/ js/ 链接
# 剔除空行、注释与缩进，减少页面发送量
package index;
use strict;
use warnings;

my $htmlfile = web/app.html
my $headend = 0;
my $dev = 1 if $ENV{SCRIPT_FILENAME} =~ m{/dev/};
my $jsmerged = 0;

print "Content-type:text/html\n";
print "\n";

open(my $fh, '<', $htmlfile) or die "cannot open $htmlfile $!";
while (<$fh>) {
	next if /^\s*$/;
	next if /<!--.*-->/g;
	$headend = 1 if m{</head>}i;
	if (!$headend) {
		if (/stylesheet/) {
			s{href="css/}{href="web/css/}g;
		}
		## 正式环境版本，链接合并的 js
		if (/<script src="js/) {
			if (!$dev && !$jsmerged) {
				s{".*?"}{web/js/app.js};
				$jsmerged = 1;
			}
			else {
				s{src="js/}{src="web/js/}g;
			}
		}
	}
	s/^\s*//g;
	print;
}
close($fh);
