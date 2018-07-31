#! /usr/bin/env perl
package NoteList;
use strict;
use warnings;
use NoteBook;
use File::Spec;

our @topic_order = qw(misc game opera snake art code);
our %topic_name = (
	misc => "随笔杂文",
	game => "游戏娱乐",
	opera => "戏曲戏剧",
	snake => "白蛇研究",
	art => "文学艺术",
	code => "程序生涯",
);

# return a list reference, each item is a line of tag file
# @param $reverse: reverse the list of content lines
sub BlogListData
{
	my ($tag, $reverse) = @_;
	my $filename = File::Spec->catfile($NoteBook::pubdir, "blog-$tag.tag");
	return '' unless -r $filename;
	return read_tag_file($filename, $reverse);
}

# return a hash reference, Prev and Next noteid in this tag file
# in the first or last, one value may empty string
sub BlogSibling
{
	my ($cur, $tag) = @_;
	my $filename = File::Spec->catfile($NoteBook::pubdir, "blog-$tag.tag");
	return {} unless -r $filename;
	
	my $content_ref = read_tag_file($filename);
	my ($prev, $next) = ('', '');

	my ($prev_may, $cur_may);
	foreach my $line (reverse @$content_ref) {
		chomp($line);
		my ($noteid, $title, $tagstr) = split(/\t/, $line);
		next unless $noteid;
		$prev_may = $cur_may;
		$cur_may = $noteid;
		if ($cur_may eq $cur) {
			$prev = $prev_may;
			next;
		}
		if ($prev_may eq $cur) {
			$next = $cur_may;
			last;
		}
	}

	return {Prev => $prev, Next => $next};
}

# 读取一个标签文件，返回数组引用
# @param $reverse: reverse the list of content lines
sub read_tag_file
{
	my ($filename, $reverse) = @_;
	open(my $fh, '<', $filename) or die "cannot open $filename $!";
	my @content = <$fh>;
	close($fh);
	if ($reverse) {
		@content = reverse(@content);
	}
	return \@content;
}

# 生成搜索框 html
sub HgenSearchForm
{
	return <<EndOfHTML;
	<div class="search-form">
	<form action="/pub/blog.cgi">
		<input type="text" name="q" />
		<input type="submit" value="搜索日志" />
	</form>
	</div>
EndOfHTML
}

# 生成导航栏 html
sub HgenTopicShow
{
	my ($this_topic) = @_;
	$this_topic ||= '';
	my $html = qq{<div class="topic-show">};
	$html .= qq{栏目分类|\n};
	foreach my $t (@topic_order) {
		my $chname = $topic_name{$t} || '';
		if ($t ne $this_topic) {
			$html .= qq{<a href="?t=$t">$chname</a>|\n};
		}
		else {
			$html .= qq{$chname|\n};
		}
	}

	$html .= qq{</div>};
	return $html;
}

# HTML generation for note list
# @param: $list_ref, note records list
# @param: $htype, html list type, 'ul' or 'ol'(default)
# @param: $option, extra query string for <a> link
sub HgenList
{
	my ($list_ref, $htype, $option) = @_;
	return '' unless $list_ref && @$list_ref;
	$htype ||= 'ol';

	# output
	my $html = qq{<$htype class="toc-notelist">\n};
	foreach my $line (@$list_ref) {
		chomp($line);
		next if $line =~ /^\s*$/;
		my ($noteid, $title, $tagstr) = split(/\t/, $line);
		my ($year, $month, $day) = $noteid =~ /^(\d{4})(\d\d)(\d\d)/;
		my $date = "$year-$month-$day";

		my $query = "n=$noteid";
		if (defined $option) {
			$query .= "&$option";
		}
		my $list = <<EndOfHTML;
	<li>
	  <span class="note-date">$date</span>
	  <span class="note-title"><a href="?$query">$title</a></span>
	</li>
EndOfHTML
		$html .= "$list";
	}

	$html .= "</$htype>\n";
	return $html;
}

1;
