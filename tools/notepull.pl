#! /usr/bin/env perl
use strict;
use warnings;

my $thisdir = '/usr/local/nginx/html/tools';
my $script = "$thisdir/everyday.sh";
my $output = qx($script);

print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head><title>Notebook Update</title></head>
<body>
<h1>Notebook Update</h1>
EndOfHTML

print $output;

print "</body></html>";

