#!/usr/bin/perl

use 5.010;
use strict;                 # install all three strictures
$|++;                       # force auto flush of output buffer
use warnings; 				# use diagnostics
no warnings 'void';			# void return values ok
use Data::Dumper;

#..............................................................................................................
# Extract Images from PDF    	
# =======================
# Use SWFTOOLS to convert PDF to SWF and extract all JPEGs from the SWF.
# The images do not contain item numbers.  The "symbols" are words, including item numbers, 
# captions, and prices.  They ideal solution for these pictures is item numbers, no prices, and 
# no page numbers, with each item shown in the set as a unique clickable product.  
# JPEGs are outputted to catimg1 in MMA_International catname directory.
#
# 06/2016  pb
#..............................................................................................................
my $restart=0;	# If good Id file exists -- $IDsIO

my $allrecs;

# my $cattype =q/beads-charms/;my $catpdf=q/beadsandcharms2016.pdf/;	# Charms and Beads catalog

# my $cattype =q/main/;my $catpdf=q/maincatalog2016.pdf/;				# Main catalog		
		
# my $cattype =q/mens/;my $catpdf=q/mens2016.pdf/;						# Men's catalog

my $cattype =q/moms-grads/;my $catpdf=q/PRICES-DELETED_momsgrads2016.pdf/;			# Moms and Grads catalog

my $jeweldir=q/C:\Users\IBM_ADMIN\Desktop\Jewelry/;

my $mmadir	=qq/$jeweldir\\MMA_International/;
my $catdir	=qq/$jeweldir\\MMA_International\\catalogs2016\\$cattype/;

my $pdfin	=qq/$catdir\\$catpdf/;

my $imgdir	=qq/$catdir\\catimg1D/;
my $imgdirw	=qq/$catdir\\catimg1D-work/;

my $swfIO 	=qq/$imgdirw\\swfimg.swf/;
my $IDsIO	=qq/$imgdirw\\swfIds.txt/;

my $swftools=q/C:\PROGRA~2\SWFTools/;

my $cmd1=qq/$swftools\\pdf2swf -i -j100 $pdfin -o$swfIO /;

if ($restart==0) {
	open(IMAGES_OUT,">$swfIO ");
	system("$cmd1");
	close(IMAGES_OUT);

	$cmd1=qq/$swftools\\swfextract $swfIO/;

	open(IMAGES_IN,"<$swfIO ");
	system("$cmd1>$IDsIO");
	close(IMAGES_IN);

	open(IDS_IN,"<$IDsIO");
	system("$cmd1>$IDsIO");
	#read(IDS_IN,$allrecs,-s IDS_IN);
	close(IDS_IN);
};

open(IDS_IN,"<$IDsIO");
while(<IDS_IN>){chomp; $allrecs.=$_};

$allrecs=~m!(?=JPEG)(.{13})(.+?)(\[\-)!;$allrecs=$2;
my @ids=split(/,? /,$allrecs);

foreach my $id (@ids) {	
	$cmd1=qq/$swftools\\swfextract $swfIO  -j$id -o$imgdir\\cat$id.jpg/;
	system("$cmd1");
};

close(IDS_IN);
say 'Fin';

exit 0;

