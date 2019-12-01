#! /usr/bin/env perl
package room;
use strict;
use warnings;

while (<>) {
	chomp;
	@_ = split;
	my $id = $_[0];
	my $name = $_[1] // '';
	my $telephone = $_[2] // '';
	print qq({"id": "$id", "name": "$name", "telephone": "$telephone"},\n);
}

