#! /usr/bin/env perl
# 默认的博客文章首页，没任何 url 参数时
package arthome;
use strict;
use warnings;

use WebPage;
use NoteList;

# 待搜索的博客栏目
my @tags = qw(misc game opera snake art code);
# 置顶文章最大篇数
my $top_article = 5;
# 新文章最大推送篇数
my $new_article = 16;
# 热门文章最大篇数，按访问量统计
my $hot_article = 10;
# 最新文章权重修正，每栏目的前五篇额外加权，基权是日期
my @new_weight = (30, 15, 7, 3, 0);

sub Response
{
	my ($title, $body) = qw(notitle nobody);
	my $head = <<EndOfHTML;
	<h2><a href="/home">七阶子行者</a>：博客首页</h2>
EndOfHTML
	$title = "七阶子博客";
	$body = top_list();
	$body .= new_list();
	$body .= hot_list();
	my $body_ref = {
		title => $title,
		articleHeader => $head,
		articleMain => $body, 
	};

	return WebPage::ResComplex($body_ref);
}

sub top_list
{
	my $html = qq{<h2>推介文章</h2>};
	return '';
}

sub new_list
{
	my $html = qq{<h2>最近文章</h2>};
	my @records = ();
	my %weights = ();

	# each tag file
	foreach my $t (@tags) {
		my $content_ref = NoteList::BlogListData($t);
		next unless $content_ref;
		# each line
		my $widx = 0;
		foreach my $line (reverse @$content_ref) {
			chomp($line);
			next if $line =~ /^\s*$/;
			my ($noteid, $title, $tagstr) = split(/\t/, $line);
			my $weight = 0 + $noteid;
			$weight += $new_weight[$widx];

			# push(@records, $line);
			$weights{$line} = $weight;

			if ($new_weight[$widx]) {
				$widx++;
			}
			else {
				last;
			}
		}
	}

	@records = sort { $weights{$b} <=> $weights{$a} } keys %weights;
	if (scalar(@records) > $new_article) {
		@records = @records[0..$new_article-1];
	}
	$html .= make_list(\@records);
	return $html;
}

sub hot_list
{
	my $html = qq{<h2>最热文章</h2>};
	return '';
}

# @param: $list_ref, note records list
# @param: $htype, html list type, 'ul' or 'ol'(default)
sub make_list
{
	my ($list_ref, $htype) = @_;
	return '' unless $list_ref && @$list_ref;
	$htype ||= 'ol';

	# output
	my $html = qq{<$htype class="toc-notelist">\n};
	foreach my $line (@$list_ref) {
		chomp($line);
		next if $line =~ /^\s*$/;
		my ($noteid, $title, $tagstr) = split(/\t/, $line);
		my $list = one_list_html($noteid, $title);
		$html .= "$list\n";
	}

	$html .= "</$htype>\n";
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

1;
