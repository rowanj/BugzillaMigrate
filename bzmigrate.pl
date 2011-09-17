#!/usr/bin/perl

use strict;

use File::Slurp;

use XML::Simple;
use Data::Dumper;
use List::MoreUtils qw/ uniq /;

use Net::GitHub::V2;

my $xml_filename  = "bugzilla.xml";
my $token_filename = "oauth_token.txt";
my $github_owner = $ENV{'GITHUB_OWNER'};
my $github_repo = $ENV{'GITHUB_REPO'};
my $github_login = $ENV{'GITHUB_LOGIN'};
my $github_token = $ENV{'GITHUB_TOKEN'};

my $bzmigrate_url = "http://goo.gl/IYYut";
my $tagline = "\n* Migrated from Bugzilla by BugzillaMigrate ($bzmigrate_url)\n";

print("Wich Bugzilla product would you like to migrate bugs from? ");
my $migrate_product = <STDIN>;
chomp($migrate_product);

if (! $github_owner )
{
    print ("Enter the owner of the GitHub repo you want to add issues to.\n");
    print ("GitHub owner: ");
    $github_owner = <STDIN>;
    chomp($github_owner);
}

if (! $github_repo )
{
    print ("Enter the name of the repository you want to add issues to.\n");
    print ("GitHub repo: https://github.com/$github_owner/");
    $github_repo = <STDIN>;
    chomp($github_repo);
}

if (! $github_login )
{
    print ("Enter your GitHub user name: ");
    $github_login = <STDIN>;
    chomp($github_login);
}

if (! $github_token )
{
    eval { $github_token = read_file($token_filename); }
}
if (! $github_token ) {
    print ("Enter your GitHub API token: ");
    $github_token = <STDIN>;
}

if (! ($github_owner &&
       $github_repo &&
       $github_login &&
       $github_token) )
{
    die("You must enter all required GitHub information.");
}

my $xml = new XML::Simple;
my $root_xml = $xml->XMLin($xml_filename,
			   ForceArray => ['long_desc']);
#print Dumper($root_xml);

my @bugs = @{$root_xml->{'bug'}};
#print Dumper(@bugs);

my $github = Net::GitHub::V2->new(
    owner => $github_owner,
    repo => $github_repo,
    login => $github_login,
    token => $ENV{'GITHUB_TOKEN'},
    throw_errors => 1
    );

foreach my $bug (@bugs)
{
#    print Dumper($bug);

    # get the bug ID
    my $id = $bug->{'bug_id'};

    # check the product
    my $product = $bug->{'product'};
    if ($product ne $migrate_product)
    {
	print ("Skipping bug #$id - wrong product (\"$product\")\n");
	next;
    }
    
    # check the status
    my $status = $bug->{'bug_status'};
    if ($status eq "RESOLVED" ||
	$status eq "VERIFIED") {
	print ("Skipping bug #$id - RESOLVED/VERIFIED\n");
	next;
    }

    my $title = "$bug->{'short_desc'} (Bugzilla #$id)";
    
    my $component = $bug->{'component'};
    my $platform = $bug->{'rep_platform'};
    my $severity = $bug->{'bug_severity'};
    my $version = $bug->{'version'};
    my $milestone = $bug->{'target_milestone'};


    # each bug has a list of long_desc for the original description
    # and each comment thereafter
    my $body .= "*$severity* in component *$component* for *$milestone*\n";
    $body .= "Reported in version *$version* on *$platform*\n\n";
    
    my $comment;
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
	$body .= ":\n\n";

	# do the body of the comment
	my $pretty_text = $desc->{'thetext'};
#	$pretty_text =~ s/ ((> )+)/\n$1/g;
#	$pretty_text =~ s/^\s+//g; # strip leading whitespace
#	$pretty_text =~ s/\s+$//g; # strip trailing whitespace
	$pretty_text =~ s/\n/\n> /g; # quote everything by one more level

	# mark up any full git refs as linkable
	$pretty_text =~ s/([0-9a-fA-F]{40})/SHA: $1/g;

	$comment++;
	$body .= "> $pretty_text\n\n";
    }

    $body .= $tagline;

#    print ("Title: $title\n$body\n\n");

    {
	#actually submit the issue to GitHub
	my $issue = $github->issue->open($title, $body);
    }
}
