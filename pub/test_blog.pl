#! /usr/bin/env perl
use strict;
use warnings;

$ENV{DOCUMENT_ROOT} = "/usr/local/nginx/html";
$ENV{QUERY_STRING} = shift;
exec "perl blog.pl";
