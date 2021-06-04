#! /usr/bin/env perl
use strict;
use warnings;

use File::Spec;
use NoteBook;
NoteBook::SetBookdirs("/usr/local/nginx/html/notebook");

my @result = ();
foreach my $topic (@NoteBook::topic_order) {
	if ($topic eq 'hot') {
		next;
	}

	my $list = NoteBook::GetBlogList($topic);
	push(@result, @$list);
}
my @sorted = reverse sort @result;
my @recent = @sorted[0..9];
my $filename = File::Spec->catfile($NoteBook::pubdir, "blog-recent.tag");

open(my $fh, '>', $filename) or die "cannot open $filename $!";
foreach my $line (@recent) {
	print $fh $line;
}
close($fh);
