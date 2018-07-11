#! /usr/bin/env perl
# handle the blog.cgi
package blog;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
# use lib "$ENV{DOCUMENT_ROOT}/pub";
use lib "$ENV{DOCUMENT_ROOT}/perl/lib";
use NoteBook;
use WebPage;
NoteBook::SetBookdirs("$ENV{DOCUMENT_ROOT}/notebook");

my $DEBUG = !$ENV{REMOTE_ADDR};
warn "Bin: $Bin\n" if $DEBUG;

# 解析 GET 参数
my $query = $ENV{QUERY_STRING};
my %query = map {$1 => $2 if /(\w+)=(\S+)/} split(/&/, $query);

exit main();

sub main
{
	my $noteid = $query{n};
	my $topic = $query{t};

	warn "noteid => $noteid\n" if $DEBUG;
	warn "topic  => $topic\n" if $DEBUG;

	if (defined $noteid) {
		require "article.pl";
		warn "load article.pl\n" if $DEBUG;
		return article::Response($noteid, $topic);
	}
	elsif (defined $topic) {
		require "artlist.pl";
		warn "load artlist.pl\n" if $DEBUG;
		return artlist::Response($topic);
	}
	else {
		my $title = "七阶子博客"; 
		my $body = "PAGE ERROR: no query string.";
		$body .= "Bin: $Bin\n";
		return WebPage::ResSimple($title, $body);
	}
	
	warn "end blog.pl\n" if $DEBUG;
}

# main end
# -------------------------------------------------- #
# sub begin

1;
