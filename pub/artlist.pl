#! /usr/bin/env perl
package artlist;
use strict;
use warnings;

use lib "$ENV{DOCUMENT_ROOT}/perl/lib";
use WebPage;
use NoteList;
use Text::Markdown qw(markdown);

my %topic_name = (
	misc => "随笔杂文",
	game => "游戏娱乐",
	opera => "戏曲戏剧",
	snake => "白蛇研究",
	art => "文学艺术",
	code => "编程技术",
);

sub Response
{
	my ($topic) = @_;
	my ($title, $body) = qw(notitle nobody);
	my $chname = $topic_name{$topic} || '';
	$title = "七阶子博客：$chname";
	$body = note_list_html($topic);
	my $head = <<EndOfHTML;
	<h2><a href="/home">七阶子博客</a>：$chname</h2>
EndOfHTML

	my $body_ref = {
		title => $title,
		articleHeader => $head,
		articleMain => $body, 
	};

	# return WebPage::ResSimple($title, $body);
	return WebPage::ResComplex($body_ref);
}

sub note_list_html
{
	my ($topic) = @_;
	my $content_ref = NoteList::BlogListData($topic);
	return '' unless $content_ref;
	
	my $html = qq{<ol class="toc-notelist">\n};
	foreach my $line (reverse @$content_ref) {
		chomp($line);
		next if $line =~ /^\s*$/;
		my ($noteid, $title, $tagstr) = split(/\t/, $line);
		my $list = one_list_html($topic, $noteid, $title);
		$html .= "$list\n";
	}

	$html .= "</ol>\n";
	return $html;
}

sub one_list_html
{
	my ($topic, $noteid, $title) = @_;
	my ($year, $month, $day) = $noteid =~ /^(\d{4})(\d\d)(\d\d)/;
	my $date = "$year-$month-$day";

	my $html = <<EndOfHTML;
	<li>
	  <span class="note-date">$date</span>
	  <span class="note-title"><a href="?t=$topic&n=$noteid">$title</a></span>
	</li>
EndOfHTML

	return $html;
}

1;
