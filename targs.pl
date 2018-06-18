#!/usr/bin/perl

use 5.010;
use strict;                 # install all three strictures
$|++;                       # force auto flush of output buffer
use warnings; 				# use diagnostics;

use Data::Dumper;
use feature 'say';

use vars qw/ %opt /;

sub init();		# prototype

#..............................................................................................................
# Build MMA Item Taxonomy
# =======================
# Find MMA item number references within HTML files.  For each item, build a set of Shopify Tags that
# correlate to the HTML file's directory structure, then remove unneeded directory tags and convert cryptic
# directory tags to meaningul tags. 
# 05/2016  pb
#..............................................................................................................

init();
print STDERR "Verbose mode ON.\n" if $opt{v};
print STDERR "Debugging mode ON.\n" if $opt{d};
return 1;


#----------------------------------------------------------------------------------------------
# Input arg processors
#----------------------------------------------------------------------------------------------
sub init() {  # Command line options processing
use Getopt::Std;
my $opt_string = 'hvdf:';
getopts( "$opt_string", \%opt ) or usage();
usage() if $opt{h};
return 1;
}

sub usage() {   # Display HELP info

print STDERR "This program does almost nothing";
print STDERR "usage: $0 [-hvd] [-f file]";
print STDERR "-h        : this (help) message";
print STDERR "-v        : verbose output";
print STDERR "-d        : print debugging messages to stderr";
print STDERR "-f file   : file containing usersnames, one per line";
print STDERR "example: $0 -v -d -f file";
print STDERR "**fin";

return 1;

}
