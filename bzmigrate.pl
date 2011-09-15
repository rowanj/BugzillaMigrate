#!/usr/bin/perl

use strict;
use Term::ReadKey;
use XML::Simple;
use Data::Dumper;

my $bzmigrate_url = "http://goo.gl/IYYut";
my $xml_filename  = "bugzilla.xml";

# TODO: filter the input file to make it more likely to parse successfully
# with XML::Simple, or use a more robust parser
#
# turn & into &amp; 
#   perl -pi.bak -e 's/&/&amp;/g' bugzilla.xml
#
# escape < when used in E-mail style:  Example Name <ename@example.com>
#   perl -pi.bak -e 's/<(\w*)@/&lt;$1@/g' bugzilla.xml
#
# For my uses, I've substituted &lt; for < in a few comments and had
# XML::Simple parse it successfully. your mileage may vary.

my $xml = new XML::Simple;
my $root_xml = $xml->XMLin($xml_filename,
			   ForceArray => ['long_desc']);
#print Dumper($root_xml);

my @bugs = @{$root_xml->{'bug'}};
#print Dumper(@bugs);

foreach my $bug (@bugs)
{
#    print Dumper($bug);
 
    my $id = $bug->{'bug_id'};
    my $title = $bug->{'short_desc'};
    my $status = $bug->{'bug_status'};
    my $preface = "* Migrated from Bugzilla by BugzillaMigrate ($bzmigrate_url)\n";

    # each bug has a list of long_desc for the original description
    # and each comment thereafter
    my $body = $preface;
    my $comment = 0;
    foreach my $desc (@{$bug->{'long_desc'}} )
    {
	# do the 'from' line of the message quote
	$body .= "On $desc->{'bug_when'}, $desc->{'who'}{'name'} wrote";
	if (UNIVERSAL::isa( $desc->{'thetext'}, "HASH" ))
	{
#	    print ("no keys in p_t\n");
	    $body .= " nothing.\n";
	    next;
	}
	$body .= ":\n";

	# do the body of the comment
	my $pretty_text = $desc->{'thetext'};
#	$pretty_text =~ s/ ((> )+)/\n$1/g;
#	$pretty_text =~ s/^\s+//g; # strip leading whitespace
#	$pretty_text =~ s/\s+$//g; # strip trailing whitespace
	$pretty_text =~ s/\n/\n> /g; # quote everything by one more level

	$body .= "> $pretty_text\n\n";
	$comment++;
    }
    print "$title (Bugzilla #$id)\n";
    print $body;
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

