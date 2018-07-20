#! /usr/bin/env perl
package WebPage;
use strict;
use warnings;

our ($title, $body);

# our (@style, @meta);
# @style = ();
# @meta = ();

# html doc string maybe large, so return scalar reference
sub LinkTitle
{
	return \$title;
}

sub LinkBody
{
	return \$title;
}

sub ResSimple
{
	my ($title_arg, $body_arg) = @_;
	$title = $title_arg if defined $title_arg;
	$body = $body_arg if defined $body_arg;
	return response();
}

sub ResComplex
{
	my ($body_ref) = @_;
	$body = body_frag($body_ref);
	$title = $body_ref->{title};
	return response();
}

sub response
{
	# http header
	print "Content-type:text/html\n\n";

	# http content
	print <<EndOfHTML;
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width" />
		<link rel="stylesheet" type="text/css" href="/css/main.css">
		<link rel="stylesheet" type="text/css" href="/css/markdown.css">
		<title> $title </title>
	</head>
	<body>
		$body
	</body>
</html>
EndOfHTML

	return 0;
}

sub body_frag
{
	my ($body_ref) = @_;
	my $site_header = $body_ref->{siteHeader} || '';
	my $site_footer = $body_ref->{siteFooter} || def_site_footer();
	my $article_header = $body_ref->{articleHeader} || '';
	my $article_main = $body_ref->{articleMain} || '';
	my $article_footer = $body_ref->{articleFooter} || '';
	
	return <<EndOfHTML;
	<div id="site-header">$site_header
	</div>
	<div id="article">
	  <div id="article-header">$article_header
	  </div>
	  <div id="article-main">$article_main
	  </div>
	  <div id="article-footer">$article_footer
	  </div>
	</div>
	<hr/>
	<div id="site-footer">$site_footer
	</div>
EndOfHTML
}

sub def_site_footer
{
	return <<EndOfHTML;
	七阶子谭，原创博客，一家之言，仅供参考。<br/>
	email: 403708621\@qq.com <br/>
	<a href="http://www.miitbeian.gov.cn/">粤ICP备18078352号</a>
EndOfHTML
}
1;
