#! /usr/bin/env perl
# handle a single blog article
package article;
use strict;
use warnings;
use lib "$ENV{DOCUMENT_ROOT}/perl/lib";
use WebPage;
use NoteFile;
use NoteList;
use Text::Markdown qw(markdown);

my $DEBUG = !$ENV{REMOTE_ADDR};

sub Response
{
	my ($noteid, $topic) = @_;
	my ($title, $body) = qw(notitle nobody);
	
	my $file_ref = NoteFile::readfile_hash($noteid);
	return response($title, $body) unless %$file_ref;

	$title = $file_ref->{title} if $file_ref->{title};

	my $body_ref = {title => $title};
	$body_ref->{articleHeader} = NoteFile::article_header($file_ref);
	my $text = join("", @{$file_ref->{content}});
	$body_ref->{articleMain} = markdown($text, {tab_width => 2});
	$body_ref->{articleFooter} = footlink($noteid, $topic);

	# return WebPage::ResSimple($title, $body);
	return WebPage::ResComplex($body_ref);
}

sub footlink
{
	my ($noteid, $topic) = @_;
	my $sibling_ref = NoteList::BlogSibling($noteid, $topic);
	return "" unless %{$sibling_ref};

	my @foot = ();
	my $prev = $sibling_ref->{Prev};
	my $next = $sibling_ref->{Next};
	$prev ? push(@foot, qq{<a href="?t=$topic&n=$prev">上一篇</a>})
	: push(@foot, qq{<a>无上一篇</a>});
	push(@foot, qq{<a href="?t=$topic">| 回列表 |</a>});
	$next ? push(@foot, qq{<a href="?t=$topic&n=$next">下一篇</a>})
	: push(@foot, qq{<a>无下一篇</a>});

	return join("\n", @foot);
}
1;
