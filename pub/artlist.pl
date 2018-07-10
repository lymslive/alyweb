#! /usr/bin/env perl
package artlist;
use strict;
use warnings;

use lib "$ENV{DOCUMENT_ROOT}/perl/lib";
use WebPage;
use NoteList;
use Text::Markdown qw(markdown);

sub Response
{
	my ($topic) = @_;
	my ($title, $body) = qw(notitle nobody);
	$title = "七阶子博客";
	$body = note_list_html($topic);

	return WebPage::ResSimple($title, $body);
}

sub note_list_html
{
	my ($topic) = @_;
	my $content_ref = NoteList::BlogListData($topic);
	return '' unless $content_ref;
	
	my $html = qq{<ol class="toc-notelist">\n};
	foreach my $line (reverse @$content_ref) {
		chomp($line);
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
