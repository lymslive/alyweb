#! /usr/bin/env perl
package blog;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";
# use lib "$ENV{DOCUMENT_ROOT}/perl/lib";
use NoteBook;
NoteBook::SetBookdirs("$ENV{DOCUMENT_ROOT}/notebook");
use MarkNote;
use HTML::Template;

my $DEBUG = !$ENV{REMOTE_ADDR};
my $query = $ENV{QUERY_STRING};
my %query = map {$1 => $2 if /(\w+)=(\S+)/} split(/&/, $query);

##-- MAIN --##
sub main
{
	my $subpath = $query{subpath};
	if ($DEBUG) {
		$subpath = shift;
	}
	if ($subpath =~ m|(\d{8}_\d+-?)\.html$|i) {
		my $noteid = $1;
		my $notefile = NoteBook::GetNotePath($noteid);
		my $markhtml = MarkNote::Convert($notefile);
		my $template = HTML::Template->new(filename => "$Bin/html/blog.html");
		$template->param(markhtml => $markhtml);
		print "Content-Type: text/html\n\n", $template->output;
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
