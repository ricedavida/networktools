#!/usr/bin/perl

use Getopt::Long;
use File::Basename;
use strict;

my $range;
my $file;
my $dryrun;
my $help;
my $filename = basename($0);


# The set of options for how this should be run
GetOptions(
    "--range=s"=>\$range,
    "--dryrun|d"=>\$dryrun,
    "--file=s"=>\$file,
    "--help|h"=>\$help,
);

# This will print instructions for how to use the program
sub help {
    print "$filename usage:\n";
    print "  Enter an ip(range) and a filename:\n";
    print " \tExample: perl $filename --range <ip/addr>/20 --file example\n";
    print "\n  Options:\n";
    print " \tperl $filename [--range] The ip(range) that you wish to scan.\n";
    print " \tperl $filename [--file] the file you will write to.\n";
    print " \tperl $filename [--dryrun] print what would have been done.\n";
    print " \tperl $filename [--help] print usage/help information.\n";
    print "\n";
    exit;
}


{ # main
    if ( !$file || !$range ) {
        &help();
    }

    # create a temp file that will store all of the ip addresses
    system("nmap -n -sP -T4 $range | 
        grep \"Nmap scan report for\" | 
        awk \'{print \$5}\' > \"$file.tmp\"");

    # if a file of the same name already exists remove it
    if(-e $file && !$dryrun) { 
        system("rm \"$file\"");
    }

    # read from the temp file replacing the ip address with the server's hostname
    open READ, "$file.tmp" or die $!;
    while (<READ>) {
        chomp($_);
        # if this is a dry run, print to standard out, otherwise write it to the file
        if ($dryrun) {
            system ("nslookup $_ \| grep \"name\" \| awk \'{print \$4}\' \| sed \'s/edu./edu/g\'");
            system ("nslookup $_ \| grep \"** server can't find \" \| awk \'{print \$1}\' \| sed \'s/**/$_/g\'");
        } else {
            system ("nslookup $_ \| grep \"name\" \| awk \'{print \$4}\' \| sed \'s/edu./edu/g\' >> \"$file\"");
            system ("nslookup $_ \| grep \"** server can't find \" \| awk \'{print \$1}\' \| sed \'s/**/$_/g\' >> \"$file\"");
        }
    }

    # clean up by removing the temp file
    system("rm \"$file.tmp\"");

    close(READ);
}
