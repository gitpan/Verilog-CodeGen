#!/usr/bin/perl -w
use strict;

use Verilog::CodeGen;

my $current='';
my $s=0;
my $d=0;
if(@ARGV){
$current=$ARGV[0];
}

if($current eq '-s') {
$current=$ARGV[1]||'';
$s=1;
$d=0;
}
if($current eq '-sd') {
$current=$ARGV[1]||'';
$s=0;
$d=1;
}
chdir 'DeviceLibs/Objects';

my @objs=();
if($current=~/\w_.*\.pl/){
push @objs,$current;
} else {
@objs=`ls -1 -t *$current*.pl`;
}

if(@objs>0) {
if($current ne '' ) {
print "Found ",scalar(@objs)," files matching $current:\n";
foreach my $item (@objs) {
print "$item";
}
}
 $current=shift @objs;
chomp $current;
} 
if($current eq 'make_module.pl') {
chomp( $current=shift @objs);
}


print '-' x 60,"\n","\tParsing $current for debugging ...\n",'-' x 60,"\n";
if( $current=~/\.pl/) {
if(not (-e $current)) {

#system("cp code_template.pl $current");
my $objname=$current;
$objname=~s/\.pl//;
&create_code_template($objname);
#system("perl -p -i -e 's/code_template/$objname/g' $current");

}
#warn("perl $current");
system("perl $current");


if($s) {
system("gnuclient -q $current");
}

if($d) {
chdir '../../TestObj';
$current=~s/\.pl//;
system("gnuclient ${current}_default.v");
}
} else {
print "No such file \n";
}
print "\n ... Done\n";
