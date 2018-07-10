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

1;
