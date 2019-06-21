#! /usr/bin/env perl
use strict;
use warnings;

use CGI;
use HTML::Template;
use FindBin qw($Bin);
use WebLog;
use File::Basename;

my $LOG = WebLog->open("$Bin/cgi.log");

my $cgi = CGI->new();
my $template = HTML::Template->new(filename => "$Bin/html/upload.html");
my $file_field = "userfile"; # 模板中 html 表单中的文件上传域名
print "Content-Type: text/html\n\n", $template->output;

# save_by_rename();
save_by_fhio();

# 操作上传文件句柄
sub save_by_fhio
{
	$LOG->addlog("save_by_fhio");
	if (my $io_handle = $cgi->upload($file_field)) {
		my $buffer;
		open ( my $out_file, '>', "$Bin/upload_io.save" );
		while ( my $bytesread = $io_handle->read($buffer,1024) ) {
			$LOG->addlog("read buff");
			print $out_file $buffer;
		}
	}
}

# 直接操作上传文件临时文件
sub save_by_rename
{
	$LOG->addlog("save_by_rename");
	my $filename = $cgi->param($file_field);
	my $filehandle  = $cgi->upload($file_field);
	my $tmpfilename = $cgi->tmpFileName( $filehandle );

	$filename = basename($filename); # 浏览器有可能传全路径？
	my $localfile = "$Bin/$filename";

	$LOG->addlog("client file name: $filename");
	$LOG->addlog("server tmp file name: $tmpfilename");
	$LOG->addlog("server save file name: $localfile");

	my $ok = rename($tmpfilename, $localfile);
	if (!$ok) {
		save_by_fhio();
		$LOG->wlog("fail to rename tmp file, change to io save");
	}
}

1;
