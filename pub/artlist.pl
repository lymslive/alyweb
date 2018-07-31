#! /usr/bin/env perl
package artlist;
use strict;
use warnings;

use WebPage;
use NoteList;

sub Response
{
	my ($topic) = @_;
	my $chname = $NoteList::topic_name{$topic} || '';
	my $title = "七阶子博客：$chname";
	my $body = '';
	my $head = <<EndOfHTML;
	<h2><a href="?">七阶子博客</a>：$chname</h2>
EndOfHTML

	$body .= NoteList::HgenSearchForm();
	$body .= NoteList::HgenTopicShow($topic);
	$body .= topic_list($topic);

	my $body_ref = {
		title => $title,
		articleHeader => $head,
		articleMain => $body, 
	};

	# return WebPage::ResSimple($title, $body);
	return WebPage::ResComplex($body_ref);
}

sub topic_list
{
	my ($topic) = @_;
	my $content_ref = NoteList::BlogListData($topic, 'reverse');
	return '' unless $content_ref;
	
	my $option = "t=$topic";
	return NoteList::HgenList($content_ref, 'ol', $option);
}

1;
