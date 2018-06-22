#! /usr/bin/env perl

my ($first, $last) = @ARGV;
foreach my $num ($first .. $last) {
	print qq{<img src="img/IMG_0$num.JPG" width="80%" /><hr/>} . "\n";
}

