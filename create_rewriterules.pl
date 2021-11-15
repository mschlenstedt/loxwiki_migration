#!/usr/bin/perl

use Data::Dumper;
use LoxBerry::JSON;

# Save data
my $jsonparser = LoxBerry::JSON->new();
my $config = $jsonparser->open(filename => "pages.json", readonly => 1);

open(FH, '>', 'htaccess');
print FH "RewriteEngine on\n\n";

foreach my $key (keys %{ $config->{'pages'} }) {
	my $serverurl = $config->{'pages'}->{"$key"}->{'ServerShortLink'};
	$serverurl =~ s/https:\/\/www.loxwiki.eu//;
	my $cloudurl = $config->{'pages'}->{"$key"}->{'CloudShortLink'};

	if ($serverurl ne "") {
		print FH "# Page Title: " . $key . "\n";
		print FH "RewriteRule   \"^" . $serverurl . "\"  \"" . $cloudurl . "\" [R=301,L]\n\n";
	}
}

close FH;
