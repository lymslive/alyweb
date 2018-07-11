#! /usr/bin/env perl
package NoteList;
use strict;
use warnings;
use NoteBook;
use File::Spec;

# return a list reference, each item is a line of tag file
sub BlogListData
{
	my ($tag) = @_;
	my $filename = File::Spec->catfile($NoteBook::pubdir, "blog-$tag.tag");
	return '' unless -r $filename;
	return read_tag_file($filename);
}

# return a hash reference, Prev and Next noteid in this tag file
# in the first or last, one value may empty string
sub BlogSibling
{
	my ($cur, $tag) = @_;
	my $filename = File::Spec->catfile($NoteBook::pubdir, "blog-$tag.tag");
	return {} unless -r $filename;
	
	my $content_ref = read_tag_file($filename);
	my ($prev, $next) = ('', '');

	my ($prev_may, $cur_may);
	foreach my $line (reverse @$content_ref) {
		chomp($line);
		my ($noteid, $title, $tagstr) = split(/\t/, $line);
		next unless $noteid;
		$prev_may = $cur_may;
		$cur_may = $noteid;
		if ($cur_may eq $cur) {
			$prev = $prev_may;
			next;
		}
		if ($prev_may eq $cur) {
			$next = $cur_may;
			last;
		}
	}

	return {Prev => $prev, Next => $next};
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
