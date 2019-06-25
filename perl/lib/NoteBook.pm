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

our @topic_order = qw(misc game opera snake art code);
our %topic_name = (
	misc => "随笔杂文",
	game => "游戏娱乐",
	opera => "戏曲戏剧",
	snake => "白蛇研究",
	art => "文学艺术",
	code => "程序生涯",
);

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

# 将日志列表转为结构化对象数组
sub StructedList
{
	my $list = GetBlogList(@_);
	my @structs = ();
	foreach my $line (@$list) {
		if ($line =~ /(\d{8}_\d+-?)\t(.+)\t\[(.+?)\]/) {
			my $id = $1;
			my $title = $2;
			my $tagstr = $3;
			my @tags = split('|', $tagstr);
			push(@structs, {id => $id, title => $title, tags => \@tags});
		}
	}
	return \@structs;
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
			# push(@{$filemark->{content}}, $_);
			chomp;
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
