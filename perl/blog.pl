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
		my $markhtml = $mark->output();
		my $title = $mark->{title};
		if (!is_blog($mark)) {
			print "404 blog not found";
			return;
		}
		my $template = HTML::Template->new(filename => "$Bin/html/blog.html");
		$template->param(blog_title => $title);
		$template->param(markhtml => $markhtml);
		print $template->output;
	}
	elsif ($subpath =~ m|^toc/(.+)\.html$|i) {
		my $topic = $1;
		my $topic_name = $NoteBook::topic_name{$topic};
		my $list = list_blog($topic, 'reverse');
		my $template = HTML::Template->new(filename => "$Bin/html/blog-list.html");
		$template->param(blog_topic => $topic_name);
		$template->param(notelist => $list);
		print $template->output;
	}
	else {
		print "404 note not found";
	}
}

##-- SUBS --##

# 根据标签判断是否确实为 blog ，避免私有日志外流
sub is_blog
{
	my ($blog) = @_;
	my $tags = $blog->{tags};
	my $ok = 0;
	foreach my $tag (@$tags) {
		if ($tag eq '-') {
			return 0;
		}
		if ($tag =~ /^blog/i) {
			$ok = 1;
			last;
		}
	}
	return $ok;
}

# 日志列表，只列出 id 与标题
sub list_blog
{
	my $list = NoteBook::GetBlogList(@_);
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
