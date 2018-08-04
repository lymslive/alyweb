#!/usr/local/bin/perl
# use lib "/home/lymslive/perl5/lib/perl5";
use URI::Escape;

print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head><title>Perl Environment Variables</title></head>
<meta charset="utf-8">
<body>
<h1>Post Data Recieved</h1>
EndOfHTML

while (<>) {
	chomp;
	print "$. : $_\n";
}


print "</body></html>";

__END__
=pod
	curl -d @file
-d 或 --date 选项会去掉文件中的换行符，实际只上传一行文本。
用 --date-binary 或 --data-urlencode 才会包含回车符。
=cut
