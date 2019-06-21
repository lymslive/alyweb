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
# use HTML::Template;

my $DEBUG = !$ENV{REMOTE_ADDR};
my $query = $ENV{QUERY_STRING};
my %query = map {$1 => $2 if /(\w+)=(\S+)/} split(/&/, $query);

##-- MAIN --##
sub main
{
	my $subpath = $query{subpath};
	if (!$subpath && $DEBUG) {
		$subpath = shift;
	}
	if (!$subpath || $subpth eq 'index.html') {
		$subpath = '20190621_4.html'
	}
	if ($subpath =~ m|(\d{8}_\d+-?)\.html$|i) {
		require "MarkNote.pm";
		require "HTML/Template.pm";
		my $noteid = $1;
		my $notefile = NoteBook::GetNotePath($noteid);
		my $markhtml = MarkNote::Convert($notefile);
		my $template = HTML::Template->new(filename => "$Bin/html/blog.html");
		$template->param(markhtml => $markhtml);
		print "Content-Type: text/html\n\n", $template->output;
	}
	elsif ($subpath =~ m|^toc/(.+)$|i) {
		my $topic = $1;
	}
	elsif ($subpath =~ m|^tag/(.+)$|i) {
		my $tag = $1;
	}
	elsif ($subpath =~ m|^day/(.+)$|i) {
		my $day = $1;
	}
	else {
		print "Content-Type: text/html\n\n", "404 note not found";
	}
}

##-- SUBS --##

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__
