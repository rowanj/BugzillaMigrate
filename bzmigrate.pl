#!/usr/bin/perl

use strict;
use Term::ReadKey;
use XML::Simple;
use Data::Dumper;

my $xml = new XML::Simple;
my $root_xml = $xml->XMLin("bugzilla.xml");
#print Dumper($root_xml);

my @bugs = @{$root_xml->{'bug'}};
#print Dumper(@bugs);

foreach my $bug (@bugs)
{
#    print Dumper($bug);
    print "\n-----------------------------------------------\n";
    print "Bug: $bug->{'bug_id'}\n";
    print "\t$bug->{'short_desc'}\n";
    print "\t$bug->{'bug_status'}\n\n";
  
    foreach my $desc (@{$bug->{'long_desc'}} )
    {
	print "\t\t$desc->{'who'}{'name'}:\n";
	print "\t$desc->{'thetext'}\n";
    }
#    die "dead.";
}

die "Submitting the parsed input is not yet done.";

print("login: ");
#my $login = ReadLine(0);

print("password: ");
ReadMode('noecho');
#my $password = ReadLine(0);
print("\n");
ReadMode('normal');

