#! /usr/bin/env perl
# handle a single blog article
package article;
use strict;
use warnings;
use lib "$ENV{DOCUMENT_ROOT}/perl/lib";
use WebPage;
use NoteFile;
use Text::Markdown qw(markdown);

my $DEBUG = !$ENV{REMOTE_ADDR};
sub init
{
	my ($noteid, $topic) = @_;
	
}

sub Response
{
	my ($noteid, $topic) = @_;
	my ($title, $body) = qw(notitle nobody);
	
	warn "$noteid\n" if $DEBUG;
	warn "$topic\n" if $DEBUG;

	my $file_ref = NoteFile::readfile_hash($noteid);
	return response($title, $body) unless %$file_ref;

	$title = $file_ref->{title} if $file_ref->{title};

	$body = NoteFile::article_header($file_ref);
	my $text = join("", @{$file_ref->{content}});
	$body .= markdown($text, {tab_width => 2});
	# fixlink();

	return WebPage::ResSimple($title, $body);
}

1;
