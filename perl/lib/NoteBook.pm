#! /usr/bin/env perl
package NoteBook;

use strict;
use warnings;

use File::Spec;

# 基础目录
our $bookdir = "";
# 各种子目录
our ($datedir, $tagdir, $chedir, $pubdir);
# 四级缓存文件
our ($day_che, $month_che, $year_che, $hist_che);
# 日期与标签统计数据文件
our ($datedb, $tagdb);

## 根据基础目录设定其他相关目录文件全路径
sub SetBookdirs
{
	$bookdir = shift;
	$bookdir = $ENV{PWD} unless defined $bookdir;
	$bookdir = $ENV{PWD} if $bookdir eq '.';

	$datedir = File::Spec->catdir($bookdir, "d");
	$tagdir = File::Spec->catdir($bookdir, "t");
	$chedir = File::Spec->catdir($bookdir, "c");
	$pubdir = File::Spec->catdir($bookdir, "p");

	$day_che = File::Spec->catfile($chedir, "day.che");
	$month_che = File::Spec->catfile($chedir, "month.che");
	$year_che = File::Spec->catfile($chedir, "year.che");
	$hist_che = File::Spec->catfile($chedir, "hist.che");

	$datedb = File::Spec->catfile($datedir, "date.db");
	$tagdb = File::Spec->catfile($tagdir, "tag.db");
}

## 根据日志ID yyyymmdd_n 获取日志的绝对路径
sub GetNotePath
{
	my ($noteid) = @_;
	return "" unless $noteid =~ /^(\d{4})(\d{2})(\d{2})_(\d+)/;
	my ($year, $month, $day, $num) = ($1, $2, $3, $4);
	my $file = "$noteid.md";
	my $path = File::Spec->catfile($datedir, $year, $month, $day, $file);
	return $path;
}

# 获取今天的年月日
sub today
{
	return ymdtime(time);
}

# 获取当月天数
sub endday($$)
{
	my ($year, $month) = @_;
	wlog("error month: $month") if $month < 1 || $month > 12;
	my @mday = (31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	return $mday[$month - 1] if $month != 2;

	# 二月要根据闰年处理一天偏差
	if ($year % 400 == 0 || $year % 4 == 0 && $year % 100 != 0) {
		return $mday[1];
	}
	else {
		return $mday[1] - 1;
	}
}

# 返回一个文件的修改时间（年月日）
sub datefile($)
{
	my $file = shift;
	my @info = stat($file);
	wlog("cannot stat($file)") && return () unless @info;
	return ymdtime($info[9]);
}

# 将时间戳转为 yyyy mm dd 三元组
sub ymdtime($)
{
	my @date = localtime(shift);
	my $day = sprintf("%02d", $date[3]);
	my $month = sprintf("%02d", $date[4] + 1);
	my $year = $date[5] + 1900;
	return ($year, $month, $day);
}

# return a list reference, each item is a line of tag file
# @param $reverse: reverse the list of content lines
sub GetBlogList
{
	my ($tag, $reverse) = @_;
	my $filename = File::Spec->catfile($pubdir, "blog-$tag.tag");
	return '' unless -r $filename;
	return read_txt_file($filename, $reverse);
}

# 读取一个标签文件，返回数组引用
# @param $reverse: reverse the list of content lines
sub read_txt_file
{
	my ($filename, $reverse) = @_;
	return [] unless ($filename && -r $filename);
	# open(my $fh, '<', $filename) or die "cannot open $filename $!";
	open(my $fh, '<', $filename) or return [];
	my @content = <$fh>;
	close($fh);
	if ($reverse) {
		@content = reverse(@content);
	}
	return \@content;
}

# 读取日志文件，解析为几部分，返回 hash
sub ReadBlogFile
{
	my ($noteid) = @_;
	my $filepath = GetNotePath($noteid);
	return undef unless ($filepath && -r $filepath);

	# the file object
	my $filemark = {
		content => [], 
		title => '', tags => [], 
		date  => '', url => '',
	};

	open(my $fh, '<', $filepath) or return undef;
	while (<$fh>) {
		# chomp;
		# title line
		if ($. == 1) {
			push(@{$filemark->{content}}, $_);
			(my $title = $_ ) =~ s/^[#\s]+//;
			$filemark->{title} = $title;
			next;
		}
		# tag line
		elsif ($. == 2){
			my @tags = /`([^`]+)`/g;
			if (@tags) {
				push(@{$filemark->{tags}}, @tags);
				next;
			}
		}

		# comment line
		if ($. < 5 && /<!--(.*)-->/) {
			my $comment = $1;
			$filemark->{date} ||= $1 if $comment =~ /(\d{4}-\d{2}-\d{2})/;
			$filemark->{url} ||= $1 if $comment =~ /(https?:\S+)/;
			next;
		}

		# 删除行首两个中文空格
		s/^　　//;
		push(@{$filemark->{content}}, $_);
	}
	close($fh);

	# the default note date
	if (!$filemark->{date}) {
		my @ymd = $noteid =~ /^(\d{4})(\d{2})(\d{2})_/;
		$filemark->{date} = join('-', @ymd);
	}

	return $filemark;
}

1;
__END__
