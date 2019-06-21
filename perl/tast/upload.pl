#! /usr/bin/env perl
package upload;
use strict;
use warnings;

# use ForkCGI;
use HTML::Template;
use FindBin qw($Bin);

my $template = HTML::Template->new(filename => "$Bin/html/upload.html");
# $template->param(markhtml => $markhtml);
print "Content-Type: text/html\n\n", $template->output;

&save_post_raw;
sub save_post_raw
{
	my ($var) = @_;
	my $post;
	{
		local $/ = undef;
		$post = <STDIN>;
	}
	if ($post) {
		my $filename = "$Bin/upload.save";
		open(my $fh, '>', $filename) or die "cannot open $filename $!";
		print $fh $post;
		close($fh);
	}
}

=pod
http web 页面表单上传文件，用 enctype="multipart/form-data" 类型
post 从标准输入收到的信息如下，用特殊串分隔成几部分。解析各文件比较复杂。
还是直接用 perl CGI 模块，或其他技术。
=cut

1;
__END__

-----------------------------1273969829406
Content-Disposition: form-data; name="userfile"; filename="create_db.sql"
Content-Type: application/octet-stream

被上传文件内容
-----------------------------1273969829406
Content-Disposition: form-data; name="redirect"

on
-----------------------------1273969829406
Content-Disposition: form-data; name="submit"

Send the file
-----------------------------1273969829406--
