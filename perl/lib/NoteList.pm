#! /usr/bin/env perl
package NoteList;
use strict;
use warnings;
use NoteBook;
use File::Spec;

sub BlogListData
{
	my ($tag) = @_;
	my $filename = File::Spec->catfile($NoteBook::pubdir, "blog-$tag.tag");
	return '' unless -r $filename;
	return read_tag_file($filename);
}

sub read_tag_file
{
	my ($filename) = @_;
	open(my $fh, '<', $filename) or die "cannot open $filename $!";
	my @content = <$fh>;
	close($fh);
	return \@content;
}

1;
