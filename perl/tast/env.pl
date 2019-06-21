#!/usr/local/bin/perl

print "Content-type:text/html\n";
# print "Set-Cookie: zzu=tansl\n";
print "\n";
print <<EndOfHTML;
<html><head><title>Perl Environment Variables</title></head>
<body>
<h1>Perl Environment Variables</h1>
EndOfHTML

foreach $key (sort(keys %ENV)) {
  print "$key = $ENV{$key}<br>\n";
}

print "</body></html>";

