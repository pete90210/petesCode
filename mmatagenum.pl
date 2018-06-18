#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
#use diagnostics;

my $path="C:\\Users\\IBM_ADMIN\\Desktop\\Jewelry\\\@TEST\\taxonomy\\dirs\\";
my $fn="LEVEL0DIRS.txt";
my $x=$path.$fn;
my $x2;
my $pathout="C:\\Users\\IBM_ADMIN\\Desktop\\Jewelry\\\@TEST\\taxonomy\\";
my $fnout="mma_tags.txt";
my $xout=$pathout.$fnout;

my $tags; my $r1=0;

open(FILEOUT,">$xout") or die "Couldn't open FILEOUT file: $!";
open(FILE, $x) or die "Couldn't open FILE file: $!";
while(<FILE>){ chomp; $x2=$_; #$r1++; if ($r1>200) {exit;}; <<<
		if ($_=~m/([A-Z])([A-Z,a-z,0-9,\-,_,\.]+)$(?<=([A-F,a-f,0-9]{4}).html)?/) {
				if (1 or not defined $3) {   # <<< nop compare
						#-------------------------------------------------
						# Strip any 4 byte hex suffix and ".html" from 
						# file name to construct candidate tags.
						# Split top10xxx to top10,xxx
						#-------------------------------------------------
						$tags=lc($1.$2);$tags=~s/[A-F,a-f,0-9]{4}.html//;$tags=~s/.html//;$tags=~s/_/,/g;$tags=~s/-/,/g;$tags=~s/top10([^_-])/top10,$1/;
						# Skip unneeded tags here <<<
						open(FILE2,$x2) or die "Couldn't open FILE2 file: $!";
						while(<FILE2>){ chomp;
								while ($_=~m/(?i)(<a href="\.\.\/jewelry\/([^\.]+)\.html" class="MedBodyCll">)+/gc) {
									print FILEOUT "$2 $tags $x2\n";

									
								};
						};		
				};
		};
};


close FILE;
close FILE2;
close FILEOUT or die "Couldn't close FILEOUT file: $xout";


print "\n**FIN\n";