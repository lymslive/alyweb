#! /usr/bin/env perl
package artsear;
use strict;
use warnings;

use WebPage;
use NoteList;

# 待搜索的博客栏目
my @tags = qw(misc game opera snake art code);
# 最大搜索结果防护
my $max_result = 100;

sub Response
{
	my ($search) = @_;
	my ($title, $body) = qw(notitle nobody);
	$title = "七阶子博客";
	$body = search_list(split /\s+/, $search);
	my $head = <<EndOfHTML;
	<h2><a href="/home">七阶子博客</a>：搜索结果</h2>
EndOfHTML

	$body .= search_form();
	my $body_ref = {
		title => $title,
		articleHeader => $head,
		articleMain => $body, 
	};

	# return WebPage::ResSimple($title, $body);
	return WebPage::ResComplex($body_ref);
}

sub search_list
{
	my @words = @_;
	return '' unless @words;

	# collect matched note records
	my @records = ();
	
	# each tag file
	foreach my $t (@tags) {
		last if $#records >= $max_result;
		my $content_ref = NoteList::BlogListData($t);
		next unless $content_ref;
		# each line
		foreach my $line (reverse @$content_ref) {
			last if $#records >= $max_result;
			chomp($line);
			next if $line =~ /^\s*$/;
			my $match = 1;
			# each search word
			foreach my $w (@words) {
				if ($line !~ /$w/) {
					$match = 0;
					last;
				}
			}
			push(@records, $line) if $match;
		}
	}

	unless (@records) {
		return qq{<p>未找到合适的文章</p>};
	}
	
	# output
	my $html = qq{<ol class="toc-notelist">\n};
	foreach my $line (@records) {
		chomp($line);
		next if $line =~ /^\s*$/;
		my ($noteid, $title, $tagstr) = split(/\t/, $line);
		my $list = one_list_html($noteid, $title);
		$html .= "$list\n";
	}

	$html .= "</ol>\n";
	return $html;
}

sub one_list_html
{
	my ($noteid, $title) = @_;
	my ($year, $month, $day) = $noteid =~ /^(\d{4})(\d\d)(\d\d)/;
	my $date = "$year-$month-$day";

	my $html = <<EndOfHTML;
	<li>
	  <span class="note-date">$date</span>
	  <span class="note-title"><a href="?n=$noteid">$title</a></span>
	</li>
EndOfHTML

	return $html;
}

sub search_form
{
	return <<EndOfHTML;
	<div class="search-form">
	<form action="/pub/blog.cgi">
		<input type="text" name="q" />
		<input type="submit" value="搜索日志" />
	</form>
	</div>
EndOfHTML
}

1;
