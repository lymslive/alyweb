#! /usr/bin/env perl
package NoteFile;
use strict;
use warnings;

use NoteBook;

# read note file as raw list
sub readfile_list
{
	my ($noteid) = @_;
	my $filepath = NoteBook::GetNotePath($noteid);
	return [] unless ($filepath && -r $filepath);
	open(my $fh, '<', $filepath) or die "cannot open $filepath $!";
	my @lines = <$fh>;
	close($fh);

	return \@lines;
}

# read markdown file, save some information with hash
# Text::Markdown fail to handle code block such as
# ```perl
# any code snippet
# ```
sub readfile_hash
{
	my ($noteid) = @_;
	my $filepath = NoteBook::GetNotePath($noteid);
	return {} unless ($filepath && -r $filepath);

	# the file object
	my $filemark = {content => [], 
		title => '', tags => [], 
		date  => '', url => '',
	};

	open(my $fh, '<', $filepath) or die "cannot open $filepath $!";
	my $codeblok = 0;
	while (<$fh>) {
		# chomp;
		# title line
		if ($. == 1) {
			push(@{$filemark->{content}}, $_);
			(my $title = $_ ) =~ s/^[#\s]+//;
			$filemark->{title} = $title;
			next;
		}
		# tag line
		elsif ($. == 2){
			my @tags = /`([^`]+)`/g;
			if (@tags) {
				push(@{$filemark->{tags}}, @tags);
				next;
			}
		}

		# comment line
		if (/<!--(.*)-->/) {
			my $comment = $1;
			$filemark->{date} ||= $1 if $comment =~ /(\d{4}-\d{2}-\d{2})/;
			$filemark->{url} ||= $1 if $comment =~ /(https?:\S+)/;
			next;
		}

		# begin/end code block ```perl
		if (/^\s*```(\S*)\s*$/) {
			my $line = $_;
			if (!$codeblok) {
				$line = qq{<pre><code class="language-$1">};
				$codeblok = 1;
			}
			else {
				$line = qq{</code></pre>\n};
				$codeblok = 0;
			}
			push(@{$filemark->{content}}, $line);
			next;
		}

		# 删除行首两个中文空格
		s/^　　//;
		push(@{$filemark->{content}}, $_);
	}
	close($fh);

	# the default note date
	if (!$filemark->{date}) {
		my @ymd = $noteid =~ /^(\d{4})(\d{2})(\d{2})_/;
		$filemark->{date} = join('-', @ymd);
	}

	return $filemark;
}

# format title
sub article_header
{
		my ($file_ref) = @_;
		my $title = $file_ref->{title};
		chomp($title);
		return "" unless $title;

		# remove the first title line
		shift(@{$file_ref->{content}});
		my $date = $file_ref->{date};
		my $url = $file_ref->{url} || 'javascript:void(0)';

		my $html = <<EndOfHTML;
		<h1>$title</h1>
		<div class="author">
		  七阶子谭 / 
		  <a href="$url">$date</a>
		</div>
EndOfHTML

		return $html;
}

# test
exit main(@ARGV) unless caller;
sub main
{
	my ($noteid) = @_;
	my $bookdir = "$ENV{HOME}/notebook";
	NoteBook::SetBookdirs($bookdir);
	my $list_ref = readfile_list($noteid);
	my $hash_ref = readfile_hash($noteid);
	# print for @$list_ref;
	print for @{ $hash_ref->{content} };
}

1;
