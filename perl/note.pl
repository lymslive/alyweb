#! /usr/bin/env perl
package blog;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";
# use lib "$ENV{DOCUMENT_ROOT}/perl/lib";
use NoteBook;
NoteBook::SetBookdirs("$ENV{DOCUMENT_ROOT}/notebook");
# use MarkNote;
use HTML::Template;
use URI::Escape;

my $DEBUG = !$ENV{REMOTE_ADDR};
my $query = $ENV{QUERY_STRING};
my %query = map {$1 => $2 if /(\w+)=(\S+)/} split(/&/, $query);

##-- MAIN --##
sub main
{
	print "Content-Type: text/html\n\n";

	my $subpath = $query{subpath};
	if (!$subpath && $DEBUG) {
		$subpath = shift;
	}
	if (!$subpath || $subpath eq 'index.html') {
		$subpath = '20190621_4.html';
	}
	if ($subpath =~ m|(\d{8}_\d+-?)\.html$|i) {
		require "MarkNote.pm";
		my $noteid = $1;
		my $notefile = NoteBook::GetNotePath($noteid);
		my $mark = MarkNote->new($notefile);
		my $markhtml = $mark->output({showtag => 1});
		my $title = $mark->{title};
		my $template = HTML::Template->new(filename => "$Bin/html/note.html");
		$template->param(note_title => $title);
		$template->param(markhtml => $markhtml);
		print $template->output;
	}
	elsif ($subpath =~ m|^tag/(.+)\.html$|i) {
		my $tag = uri_unescape($1);
		my $list = list_note($tag, 'reverse');
		my $template = HTML::Template->new(filename => "$Bin/html/note-list.html");
		$template->param(note_tag => $tag);
		$template->param(notelist => $list);
		print $template->output;
	}
	elsif ($subpath =~ m|^day/(.+)\.html$|i) {
		my $day = $1;
	}
	else {
		print "404 note not found";
	}
}

##-- SUBS --##

# 日志列表，只列出 id 与标题
sub list_note
{
	my $list = NoteBook::GetNoteList(@_);
	my @structs = ();
	foreach my $line (@$list) {
		if ($line =~ /(\d{8}_\d+-?)\t(.+)\t\[(.+?)\]/) {
			my $id = $1;
			my $title = $2;
			my $year = substr($id, 0, 4);
			my $month = substr($id, 4, 2);
			my $day = substr($id, 6, 2);
			my $date = "$year-$month-$day";
			push(@structs, {id => $id, title => $title, date => $date});
		}
	}
	return \@structs;
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__
