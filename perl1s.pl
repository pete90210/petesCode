#!/usr/bin/perl

use 5.010;
use strict;                 # install all three strictures
$|++;                       # force auto flush of output buffer
use warnings; 				# use diagnostics
no warnings 'void';			# void return values ok
use Data::Dumper;

#..............................................................................................................
# Generate a redaction file for Adobe Acrobat DC Pro to delete prices and page numbers    	
# ====================================================================================
# 06/2016  pb
#..............................................................................................................
my $price_decimals=0; 	# Price decimal places (0-2)
my $price_max=2000;		# Max price generated

my $jeweldir=q/C:\Users\IBM_ADMIN\Desktop\Jewelry/;
my $mmadir	=qq/$jeweldir\\MMA_International/;
my $catdir	=qq/$jeweldir\\MMA_International\\catalogs2016/;
my $redactFileOut=qq/$catdir\\redact.txt/;


open(REDACT_OUT,">$redactFileOut");
my $p=1;

do {
	my $rec="\$$p";
	# say $rec;
	$p+=1;
	print REDACT_OUT "$rec\n";
} until $p>$price_max;

close(REDACT_OUT);
say 'Fin';

exit 0;

