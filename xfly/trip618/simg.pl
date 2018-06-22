#! /usr/bin/env perl

my @bak = glob('*.html.bak');

foreach my $bakfile (@bak) {
	print "$bakfile\n";
	deal_one($bakfile);
}


sub deal_one
{
	my $bakfile = shift;
	(my $htmfile = $bakfile) =~ s/\.bak$//;

	open(my $fhin, '<', $bakfile) or die "cannot open $bakfile $!";
	open(my $fhout, '>', $htmfile) or die "cannot open $htmfile $!";

	while (<$fhin>) {
		if (/<img.*IMG_(\d+).*?>/) {
			my $num = $1;
			s{img/IMG}{simg/SIMG};
			s{(<img.*?>)}{<a href="img/IMG_$num.JPG">$1</a>};
		}
		print $fhout $_;
	}

	close($fhout);
	close($fhin);
}


