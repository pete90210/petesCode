#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
#use diagnostics;

my $path="C:\\Users\\IBM_ADMIN\\Desktop\\Jewelry\\\@TEST\\taxonomy\\dirs\\";
my $fn="LEVEL0DIRS.txt";
my $x=$path . $fn;
my $x2;

my $tags;

#my @tagitems;my $xtc=0; my $xic=0;my $axic=0;
#my @ptagitems;

open(FILE, $x) or die "Couldn't open file: $!";
while(<FILE>){ chomp; $x2=$_;
		if ($_=~m/([A-Z])(([A-Z,a-z,\-,_,\.]){6,})$/) { 
				$tags=lc($1.$2);$tags=~s/.html//;$tags=~s/_/,/g;$tags=~s/-/,/g;

				open(FILE2,$x2) or die "Couldn't open file: $!";
				while(<FILE2>){ chomp;
						#$xic=0;
						while ($_=~m/(?i)(<a href="\.\.\/jewelry\/([^\.]+)\.html" class="MedBodyCll">)+/gc) {
								my $ss=substr($2,length($2)-3,4);
								if ($ss ne "adcd" and $ss ne "dcbf" and $ss ne "fdce" and $ss ne "cdbb" and $ss ne "bcda" and 
								    $ss ne "afee" and $ss ne "babd") {
									print "$2 $tags $x2\n";
								};
						};		
				};
		};
};

close FILE;
close FILE2;


print "\n**FIN\n";



#$tagitems[$xtc++]=$tags;
#$ptagitems[$xtc]=\$tagitems[$xtc];
#print "added tag $tags\n";

#$tagitems[$xtc][$xic++]=$2;#print "added item_num $2\n";
#$ptagitems[$xtc][$xic]=\$tagitems[$xtc][$xic];

# print the tagitem array

#print "$ptagitems[1][0]\n";
#print "$ptagitems[1]->$tagitems[0]\n";

#my $q=$p->[1];
#print "$p->$q->$tagitems[0]\n";
#print "here\n";
#print "aaaa $p->$tagitems[1][1]\n";
#print "bbbb $tagitems[$p]->[2]\n";
#print "$p->$tagitems[0][2]\n";
#print "$tagitems[0][1]\n";
#print "$tagitems[0][2]\n";

 #use Data::Dumper qw(Dumper);
 #print Dumper \@tagitems;
 
# {}[]()^$.|*+?\ -- all regexp metacharacters in perl <<<


# if ($tags=~m/[\\](.*).html$/) {#print "tags=$1\n";};


# my $path="C:\\Users\\IBM_ADMIN\\Desktop\\Jewelry\\MMA_International\\webcrawl\\MMA1\\www.mmasilver.com\\silverstars\\";
# my $fn="Top10Charms.html";
# my $fn="Akoya.html";

# my $_="C:\\Users\\IBM_ADMIN\\Desktop\\Jewelry\\MMA_International\\webcrawl\\MMA1\\www.mmasilver.com\\silverstars\\";

# my $fn="Top10Charms4B16.html";
# my $fn="Bracelet-Bangle.html";

#my $_="<";								#parse HTML with Internal Record Separator 


#				my $rx1=defined $1 ? $1 : '';	
#				my $rx2=defined $2 ? $2 : '';	
#				print "$rx1$rx2\n";



		# if ($_=~m/([A-Z])(([a-z,\-,_,\.])$/) {
		# ^([a-f][a-f][a-f][a-f])




# ([a-f][a-f][a-f][a-f])

# print "Record=!!$_!!\n"; 							#shows you what we have read

# if ($_=~m/(?i)((top10)*([a-z,\-,_,\.]{7,})$)/) { 	
# if ($_=~m/([A-Z][a-z,\-,_,]*)$/) {



# print "rx=$rx\n";

# (\*(top10)*([a-z,-,_,.])*)

# if ($x=~m/$rx/g) { print "match\n";						# ending g = multiple matches

# my $rx="(?i)													# case insensitive
	# \Q																# escape all metacharacters
	# (.*(top10)*([a-z,-,_,.])*)
	# \$																# anchor end-of-line or string 
	# \E																# close /Q 
	# \x";																# allow whitespace in regexp



