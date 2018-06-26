#!/usr/bin/perl

use 5.010;
use strict;                 # install all three strictures
$|++;                       # force auto flush of output buffer
use warnings; 				# use diagnostics;

# use Data::Dumper;
# use feature 'say';

use vars qw/ %opt /;

init();
print STDERR "Verbose mode ON.\n" if $opt{v};
print STDERR "Debugging mode ON.\n" if $opt{d};
return 1;


# ------------------------------------------------------------------------------------------------------------- 
# Process options passed to a program using getopts().
# ------------------------------------------------------------------------------------------------------------- 
# Make a global hash to store the options. Use the standard Getopt module. Make a string of one-character    
# options. A character preceeding a colon takes an argument. The getopts function takes two arguments: a string 
# of options, and a hash reference. For each command line option (aka switch) found, getopts sets $opt{x} 
# (where x is the switch name) to the value of the argument, or 1 if no argument was provided.
#
# Reference: http://www.cs.mcgill.ca/~abatko/computers/programming/perl/howto/getopts/
# ------------------------------------------------------------------------------------------------------------- 
# 05/2016  pb
# ------------------------------------------------------------------------------------------------------------- 


sub init() {  # Command line options processing
use Getopt::Std;
my $opt_string = 'hvdf:';
getopts( "$opt_string", \%opt ) or usage();
usage() if $opt{h};
return 1;
}



sub usage() {   # Display HELP info

print {"STDERR"} "This program does almost nothing";
print {"STDERR"} "usage: $0 [-hvd] [-f file]";
print {"STDERR"} "-h        : this (help) message";
print {"STDERR"} "-v        : verbose output";
print {"STDERR"} "-d        : print debugging messages to stderr";
print {"STDERR"} "-f file   : file containing usersnames, one per line";
print {"STDERR"} "example: $0 -v -d -f file";
print {"STDERR"} "**fin";

return 1;

}
