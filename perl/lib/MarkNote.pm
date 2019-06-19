#! /usr/bin/env perl
package MarkNote;
use strict;
use warnings;

sub output
{
	my ($filepath, $option) = @_;
	return "" unless $filepath;

	open(my $fh, '<', $filepath) or return "";
	my $out = parse($fh, $option);
	close($fh);

	return $out;
}

sub parse
{
	my ($fh, $option) = @_;
	if ($option && $option->{extra_struct}) {
		$option->{struct} = {};
	}

	my @out_buffs = ();
	my $out_string = 0;
	my $last_line = "";
	my $this_line = "";
	my @pargraph = ();
	my $title = "";
	my $tag_line = "";
	my @tags = ();

	while (<$fh>) {
		$last_line = $this_line;
		$this_line = $_;
		my $empty_line = ($this_line =~ /^\s*$/ ? 1 : 0);

		if ($this_line =~ /^\s*(#+)\s*/) {
			my $head_level = length($1);
			my $head_string = $this_line;
			$head_string =~ s/^\s*#+\s*//;
			$head_string =~ s/\s*$//;
			push(@out_buffs, html_head($head_level, $head_string));

			if (!$title) {
				$title = $head_string;
				if ($option->{extra_struct}) {
					$option->{extra_struct}->{title} = $title;
				}
			}

			next;
		}

		# 首次遇到标签行
		if (!$tag_line && $. < 3 && $this_line =~ /^\s*`.*`\s*$/) {
			$tag_line = $this_line;
			@tags = /`([^`]+)`/g;
			if (@tags && $option->{extra_struct}) {
				push(@{$option->{extra_struct}->{tags}}, @tags);
				next;
			}
		}
	}

	my $out_string = join("\n", @out_buffs);
	return $out_string;
}

sub html_head
{
	my ($head_level, $head_string) = @_;
	my $tag = "h" . $head_level;
	return qq{<$tag>$head_string</$tag>};
}
