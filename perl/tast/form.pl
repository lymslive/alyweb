#!/usr/local/bin/perl
# use lib "/home/lymslive/perl5/lib/perl5";
use URI::Escape;

print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head><title>Perl Environment Variables</title></head>
<meta charset="utf-8">
<body>
<h1>Please Fill the Form</h1>

<form method="post">
First name:<br>
<input type="text" name="firstname" value="Mickey">
<br>
Last name:<br>
<input type="text" name="lastname" value="Mouse">
<br><br>
<input type="submit" value="Submit">
</form>

<h1>Post Data Recieved</h1>
EndOfHTML

$/='&';
while (<>) {
	chomp;
	print "$. : $_<br>\n";
}


print "</body></html>";

__END__
=pod
通过表单提交的数据是一行：
	1 : firstname=Mickey&lastname=Mouse
多个域用 & 分隔，类似 get 参数，只是可以更长

可以重设 $/ = '&' 分别读入每个域
	1 : firstname=Mickey
	2 : lastname=Mouse
最好 local $/ 局部化

=cut
