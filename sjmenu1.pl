#!/usr/bin/perl

use 5.010;
use strict;                 # install all three strictures
$|++;                       # force auto flush of output buffer
use warnings; 				# use diagnostics
no warnings 'void';			# void return values ok
use Data::Dumper;

#..............................................................................................................
# Generate HTML from Templates
# ============================
#
# 06/2016  pb
#..............................................................................................................


use Text::CSV;				# CSV Parser


my @template00=(
	'<nav id="!!collName!!" class="navbar navbar-fixed"></nav>	<!-- dummy nav for spacing -->',
	'<div id="!!collName!!0" class="row">',
	'	<div class="col-md-12">',
	'		<div class="well well-sm center"><h3><span class="label label-primary">!!collTitle!!</span></h3><br>',
	'		</div>',
	'	</div>',
	'</div>',
	'',
);

my @template10=(
	'<div id="!!collName!!1" class="col-md-3 col-sm-6">',
	'	<div class="collection-hdr">!!ollTitle!!</div>',
	'		<img class="img-responsive img-rounded center-block" alt="!!imgTitle!!" src="!!imgSrc!!"></img>',
	'	</div>',
	''
	);

my $template20_headr = 'div class="btn-group btn-group-xs" role="group">';
my @template20=(
	'<a href="#" class="btn btn-info btnpad2 role="button">!!btnTitle!!</a>',
	);
my $template20_footr = '</div>';


my $jeweldir=q/C:\Users\IBM_ADMIN\Desktop\Jewelry/;
my $mmadir	=qq/$jeweldir\\MMA_International/;

# This is the csv formatted values that are plugged into the
# HTML templates defined by the @template## tables.  These
# are Shopify collection definitions.
my $collectionDefFile = qq/imgdirw\\swfimg.swf/; #INPUT

# This is the output HTML.
my $newHTMLFile = qq/imgdirw\\swfimg.swf/; #OUTPUT

my $templLine;

my $csv = Text::CSV->new ({
  binary    => 0,
  auto_diag => 1,
  sep_char  => ','    # comma is default
});

open(my $newHTML,'>',$newHTMLFile);
open(my $collDef,'<',$collectionDefFile);

while (my @inLine = $csv->getline($collDef)){

	my $menuType 	= $inLine[1];		# Button
	my $collName	= $inLine[2];
	my $collTitle	= $inLine[3];
	my $btnTitle	= $inLine[4];
	my $imgSrc		= $inLine[3];
	my $imgTitle	= $inLine[3];

	foreach $templLine (@template00)	{
		$templLine=~s/!!collName!!/$collName/;
		$templLine=~s/!!collTitle!!/$collTitle/;
		print $newHTML "$templLine\n";
	};

	foreach $templLine (@template10)	{
		$templLine=~s/!!collName!!/$collName/;
		$templLine=~s/!!collTitle!!/$collTitle/;
		$templLine=~s/!!imgTitle!!/imgAlt/;
		$templLine=~s/!!imgSrc1!!/imgSrc/;
		print $newHTML "$templLine\n";
	};
	
	if ($menuType=='buttonHeader1') {print $newHTML "$template20_headr\n";};
	
	if ($menuType=='button1') {
		foreach $templLine (@template20) {
			$templLine=~s/!!btnTitle1!!/$btnTitle/;
			print $newHTML "$templLine\n";
		};
	};
		
	if ($menuType=='buttonFooter1') {print $newHTML "$template20_footr\n";};
		print $newHTML "$template20_footr\n";
	};


close($collDef);
close($newHTML);

say 'Fin';

exit 0;
