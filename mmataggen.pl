#!/usr/bin/perl

use 5.010;
use strict;                 # install all three strictures
$|++;                       # force auto flush of output buffer
use warnings; 				# use diagnostics;

use Data::Dumper;
use feature 'say';

#..............................................................................................................
# Build MMA Item Taxonomy
# =======================
# Find MMA item number references within HTML files.  For each item, build a set of Shopify Tags that
# correlate to the HTML file's directory structure, then remove unneeded directory tags and convert cryptic
# directory tags to meaningul tags. 
# 05/2016  pb
#..............................................................................................................

my $TagDir="C:\\Users\\IBM_ADMIN\\Desktop\\Jewelry\\\@TEST\\tags\\";
my $DirFileIn="LEVEL0DIRS.txt";
my $filTagsOut="mma_tags.txt";
my $filTagsAllOut="tags_all.txt";
my $filItemXrefOut="item_xref.txt";

my $DirListIn=$TagDir.$DirFileIn;
my $TagsOut=$TagDir.$filTagsOut;
my $TagsAllOut=$TagDir.$filTagsAllOut;
my $ItemXOut=$TagDir.$filItemXrefOut;

my $HTML_FileName;
my $WorkTags;
my $ItemNumTagged;

# These tags are discarded...
my @skip_tags=("closefivedollar","closeall","closeb","woscc","closen","bv","or","view","er","ss","ex","trbjothr","other","view all","style","all","ringsize","woscsn","webearrings","webbracelets","webnecklaces","woscr","sbm","closeps","closeunder25","ringall","2","elementsofcharm","brall","watchesall","closew","closetendollar","neck","theme","back","sneakpreview","finding","webother","jewelry","close","mjn","ringall","closee","filled","fp","closeundertwentyfive","wosch","mjb","closeovertwentyfive","webrings","closer","closeo","closeps","woscf",
"closedollar","closeout","new","arrivals","mjo","designs","glamour","mjr","aa","aaa","woscm","mjn","watchesall","webpendants","viewall","na","inspired","8in");

#------------------------------------------------------------------------------------------- 
# TAG notes:
#------------------------------------------------------------------------------------------- 
#
#   Skip tag "ringsize" should be ringsize## where ## is an actual size - edited below to "ring"
#
#
#   TAG changes and abbreviations:
#
#		fj = Fashion Jewelry  
#		TR = TRENDS
#		COY,coy# = COLOR OF THE YEAR (according to Pantone)
#		NA = NEW ARRIVALS (removed)
#		LIMITED, EDITION = LIMITED EDITION
#		RIGHT, HAND = STATEMENT RINGS
#		trchrmlob = LOBSTERCLASPCHARM  
#			necklace and bracelet lobster clasp also in separate dirs
#		CELEB, INSPIRED = CELEBRITYINSPIRED
#		bi, tri = biandtritone - check if can be 2 tags
#
#		ST = STYLES AND TRENDS
#		FP = FASHION PREVIEW (removed)
#		SBM = SHOP BY MATERIAL (removed)
#		PR = precious metal
#		FWSILVER = FRESHWATER PEARLS WITH SILVER
#		PPS = PENDANTS AND SLIDES
#		CT = CHILDREN'S
#		TRBJ = TOE RINGS AND BODY JEWELRY
#		TRBJTR = TOE RINGS
#		TRBJA = ANKLETS
#		TRBJNS = NOSE STUDS
#		WOSC = CHAIN
#		BRP = BLACK RHODIUM PLATED
#		WOSCCH = CHARM CHAIN
#		WOSCRO = RHODIUM PLATED CHARM (I'M NOT SURE WE NEED THIS)
#		GEOTR = CIRCLES/GEOMETRIC
#		WOSCBO = BOX CHAIN
#------------------------------------------------------------------------------------------- 

my @tag;
my @xitem;
my @TranslatedTag;
my $TranslatedTag;

my $tag_hash={};   # associative key item_num:tag
my $item_hash={};  # hashed item_num and assoc. tags

my $xtag_hash={};   # associative key tag:item_num 		for xref report
my $xitem_hash={};  # hashed tag and assoc. item_nums 	for xref report

open(DIRLISTIN,	"<$DirListIn")		or die "Could not open DIRLISTIN file: $!";
open(TAGSOUT,	">$TagsOut") 		or die "Could not open TAGSOUT file: $!";
open(ITEMXOUT,	">$ItemXOut") 		or die "Could not open ITEMXOUT file: $!";
open(TAGSALLOUT,">$TagsAllOut") 	or die "Could not open TAGSALLOUT file: $!";


while(<DIRLISTIN>){ chomp; $HTML_FileName=$_;
	if (($WorkTags=HTML_ContainsCandidateTags($HTML_FileName))) {
		open(HTMLFILEIN,$HTML_FileName) or die "Could not open HTMLFILEIN file: $!";
		while(<HTMLFILEIN>){ chomp;
			while ($_=~m/(?i)(<a href="\.\.\/jewelry\/([^\.]+)\.html" class="MedBodyCll">)+/gc) {$ItemNumTagged=$2;
				@tag=split(/,/,$WorkTags);
				foreach my $tag (@tag) {
					# Skip unneeded tags here 
					if (not grep(/^$tag$/,@skip_tags)) {
						@TranslatedTag=FinalizeTag($tag);   # Translate tag abbreviations to meaningful tag
						foreach $TranslatedTag (@TranslatedTag) {
							# Associative array tag_hash
							if (not defined $tag_hash->{ $ItemNumTagged.':'.$TranslatedTag }){
								$tag_hash->{ $ItemNumTagged.':'.$TranslatedTag }=1;
								$item_hash->{ $ItemNumTagged }.=$TranslatedTag.','; 
							};
							# Associative array tag_hash #2
							if (not defined $xitem_hash->{ $TranslatedTag.':'.$ItemNumTagged }){
								$xitem_hash->{ $TranslatedTag.':'.$ItemNumTagged }=1;
								$xtag_hash->{ $TranslatedTag }.=$ItemNumTagged.','; 
							};
						};
					} 
					# else {print "  skipped $tag";};    
				};		
			};
		};
		close HTMLFILEIN or die "Could not close HTMLFILEIN file: $!";		
	};
};
	

while ( my ($ItemNumTagged, $WorkTags) = each(%$item_hash) ) {
	print TAGSOUT "$ItemNumTagged $WorkTags\n";
};				
			
my $t = localtime;
print TAGSALLOUT "List of All Tags -- $t\n\n";
print ITEMXOUT "Tag to Item XRef -- $t\n\n";

while ( my ($WorkTags,$ItemNumTagged) = each(%$xtag_hash) ) {
	print TAGSALLOUT "$WorkTags\n";
	print ITEMXOUT "\n\n=============================================\n";
	print ITEMXOUT "_________________ $WorkTags _________________\n";
	@xitem=split(/,/,$ItemNumTagged);
	foreach my $xitem (@xitem) {	
		print ITEMXOUT "$xitem\n";
	};
};							



#say Dumper($item_hash);

close DIRLISTIN		or die "Could not close DIRLISTIN file: $!";
close TAGSOUT 		or die "Could not close TAGSOUT file: $!";
close ITEMXOUT 		or die "Could not close ITEMXOUT file: $!";
close TAGSALLOUT 	or die "Could not close TAGSALLOUT file: $!";

print "\n**FIN\n";

exit (0);
######### END MAIN ############################################################################




#----------------------------------------------------------------------------------------------
# Split top10xxx to top10,xxx.
# Glue together special Tag values.
#----------------------------------------------------------------------------------------------
sub HTML_ContainsCandidateTags{

my $iHTML=$_[0];		# Input Arg is html directory and filename.

if ($iHTML=~m/([A-Z])([A-Z,a-z,0-9,\-,_,\.]+)$(?<=([A-F,a-f,0-9]{4}).html)?/) {
	#------------------------------------------------------------------------------------------- 
	# Strip any 4 byte hex suffix and ".html" from file name to construct candidate tags.
	# $3 is hex filename suffix (eg. Braceletsadcd.html).
	# Change any other special tag names here (eg, right_hand_cocktail).
	#------------------------------------------------------------------------------------------- 
	$WorkTags=lc($1.$2);
	$WorkTags=~s/[a-f,0-9]{4}.html//;
	$WorkTags=~s/.html//;

	$WorkTags=~s/right_hand_cocktail/righthand,cocktail/;
	$WorkTags=~s/celeb_inspired/celebrity/;
	$WorkTags=~s/_/,/g;
	$WorkTags=~s/-/,/g;
	$WorkTags=~s/swarvoski/swarovski/;
	$WorkTags=~s/top(?:10|ten)(.+)/top10,$1/;
	$WorkTags=~s/silverbasics.*/silver,basics,diana vreeland/;
	$WorkTags=~s/stainlessbracelets.*/stainless,bracelet/;
	$WorkTags=~s/mo(m|ther)[s]*day.*/mothersday,holiday,occasion,mom/;
	$WorkTags=~s/leatherbracelets/leather,bracelet/;
	$WorkTags=~s/(mma)?engrav[e]?able/engraveable/;
	$WorkTags=~s/pantone.+/pantone/;
	$WorkTags=~s/wrapbracelet[s]?/wrap,bracelet/;
	$WorkTags=~s/altmetal[s]?/altmetal,metal/;
	$WorkTags=~s/toe ring[s]?/toering/;
	
	return $WorkTags;
}

else {return "";}	# Ignored OK

}




#----------------------------------------------------------------------------------------------
# Nice up the Tag names.
#----------------------------------------------------------------------------------------------
sub FinalizeTag{

my @TranslatedTag;

$TranslatedTag[0]=$_[0];		# Input Arg

if    ($TranslatedTag[0] eq 'tr') 				{$TranslatedTag[0]='trend';}
elsif ($TranslatedTag[0] eq 'st') 				{$TranslatedTag[0]='trend';}
elsif ($TranslatedTag[0] eq 'fj') 				{$TranslatedTag[0]='fashion';}
elsif ($TranslatedTag[0] eq 'ct') 				{$TranslatedTag[0]='children';}
elsif ($TranslatedTag[0] eq 'pps') 				{$TranslatedTag[0]='pendantsslides';}

elsif ($TranslatedTag[0] eq 'geometricrings') 	{$TranslatedTag[0]='geometric';
												$TranslatedTag[1] ='ring';}

elsif ($TranslatedTag[0] eq 'wosc') 			{$TranslatedTag[0]='chain';}

elsif ($TranslatedTag[0] eq 'woscch') 			{$TranslatedTag[0]='chain';
												$TranslatedTag[1] ='charm chain';}
									 
elsif ($TranslatedTag[0] eq 'woscro') 			{$TranslatedTag[0]='chain';
												$TranslatedTag[1] ='circle';
												$TranslatedTag[2] ='geometric';}

elsif ($TranslatedTag[0] eq 'woscro') 			{$TranslatedTag[0]='chain';
												$TranslatedTag[1] ='rhodium';}

elsif ($TranslatedTag[0] eq 'woscbo') 			{$TranslatedTag[0]='chain';
												$TranslatedTag[1] ='box chain';}
	
elsif ($TranslatedTag[0] eq 'pr') 				{$TranslatedTag[0]='precious metal';}

elsif ($TranslatedTag[0] eq 'trbj') 			{$TranslatedTag[0]='body jewelry';
												$TranslatedTag[1] ='toering';}
									
elsif ($TranslatedTag[0] eq 'trbjtr') 			{$TranslatedTag[0]='body jewelry';
												$TranslatedTag[1] ='toering';}
									
elsif ($TranslatedTag[0] eq 'trbja') 			{$TranslatedTag[0]='body jewelry';
												$TranslatedTag[1] ='anklet';}
									
elsif ($TranslatedTag[0] eq 'trbjns') 			{$TranslatedTag[0]='body jewelry';
												$TranslatedTag[1] ='nose stud';}
									
elsif ($TranslatedTag[0] eq 'brp') 				{$TranslatedTag[0]='rhodium';
												$TranslatedTag[1] ='plated';
												$TranslatedTag[2] ='black';}
									
elsif ($TranslatedTag[0]=~m/^ringsize\d+$/) 	{$TranslatedTag[0]='ring';}

elsif ($TranslatedTag[0]=~m/^coy\d*$/) 			{$TranslatedTag[0]='pantone';}

elsif ($TranslatedTag[0]=~m/.+lob$/) 			{$TranslatedTag[0]='lobsterclasp';}

elsif ($TranslatedTag[0] eq 'fwsilver') 		{$TranslatedTag[0]='pearl';
												$TranslatedTag[1] ='silver';}

return @TranslatedTag;

}