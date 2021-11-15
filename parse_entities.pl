#!/usr/bin/perl

use XML::Simple qw(:strict);
use Data::Dumper;
use LoxBerry::JSON;
use Encode;
use LWP::UserAgent;

my %wikipages;

$urlserver = "https://www.loxwiki.eu/pages/viewinfo.action?pageId=";
$urlcloud = "https://loxwiki.atlassian.net/wiki/pages/viewinfo.action?pageId=";

$refserver = XMLin('server_entities.xml', KeyAttr => { property => 'name' }, ForceArray => 1 );
$refcloud = XMLin('cloud_entities.xml', KeyAttr => { property => 'name' }, ForceArray => 1 );

# Parse Server
foreach (@{ $refserver->{'object'} }) {
	if ($_->{'package'} ne "com.atlassian.confluence.pages" || $_->{'class'} ne "Page") {
		next;
	}
	my $id = $_->{'id'}->[0]->{'content'};
	$id =~ s/\R//g;
	$id =~ s/^\s*(.*?)\s*$/$1/;
	my $lowertitle = $_->{'property'}->{'lowerTitle'}->{'content'};
	$lowertitle =~ s/\R//g;
	$lowertitle =~ s/^\s*(.*?)\s*$/$1/;
	$lowertitle = Encode::encode("UTF-8", $lowertitle);
	if ($lowertitle ne "" && !$wikipages->{"$lowertitle"}->{"ServerPageID"}) {
		my $ua = new LWP::UserAgent;
		my $url = $urlserver . $id;
		my $res = $ua->get($url);
		my $html = $res->decoded_content();
		my $urlstatus = $res->status_line;
		my $urlstatuscode = substr($urlstatus,0,3);
		if ($urlstatuscode ne "200") {
			print "Fail $url Status Code: $urlstatuscode\n";
			next;
		}
		my $pre;
		my $shortlink;
		my $post;
		foreach (split(/\n/,$html)) {
			$_ =~ /(<link rel="shortlink" href=")(.*)(">)/ || next;
			($pre,$shortlink,$post) = ($1,$2,$3);
		}
		if ($shortlink eq "") {
			next;
		}
		print "Server PageID: $id | Short Link: $shortlink | Title: $lowertitle\n";
		$wikipages->{"$lowertitle"}->{"ServerPageID"} = $id;
		$wikipages->{"$lowertitle"}->{"ServerShortLink"} = $shortlink;
	}
	sleep 0.5;
}

# Parse Cloud
foreach (@{ $refcloud->{'object'} }) {
	if ($_->{'package'} ne "com.atlassian.confluence.pages" || $_->{'class'} ne "Page") {
		next;
	}
	my $id = $_->{'id'}->[0]->{'content'};
	$id =~ s/\R//g;
	$id =~ s/^\s*(.*?)\s*$/$1/;
	my $lowertitle = $_->{'property'}->{'lowerTitle'}->{'content'};
	$lowertitle =~ s/\R//g;
	$lowertitle =~ s/^\s*(.*?)\s*$/$1/;
	$lowertitle = Encode::encode("UTF-8", $lowertitle);
	if ($lowertitle ne "" && !$wikipages->{"$lowertitle"}->{"CloudPageID"} && $wikipages->{"$lowertitle"}->{"ServerPageID"}) {
		my $ua = new LWP::UserAgent;
		my $url = $urlcloud . $id;
		my $res = $ua->get($url);
		my $html = $res->decoded_content();
		my $urlstatus = $res->status_line;
		my $urlstatuscode = substr($urlstatus,0,3);
		if ($urlstatuscode ne "200") {
			print "Fail $url Status Code: $urlstatuscode\n";
			next;
		}
		my $pre;
		my $shortlink;
		my $post;
		foreach (split(/\n/,$html)) {
			$_ =~ /(<link rel="shortlink" href=")(.*)(">)/ || next;
			($pre,$shortlink,$post) = ($1,$2,$3);
		}
		if ($shortlink eq "") {
			next;
		}
		print "Cloud PageID: $id | Short Link: $shortlink | Title: $lowertitle\n";
		$wikipages->{"$lowertitle"}->{"CloudPageID"} = $id;
		$wikipages->{"$lowertitle"}->{"CloudShortLink"} = $shortlink;
	}
	sleep 0.5;
}

# Save data
my $jsonparser = LoxBerry::JSON->new();
my $config = $jsonparser->open(filename => "pages.json", writeonclose => 1);
$config->{'pages'} = \%{ $wikipages };
$jsonparser->write();
