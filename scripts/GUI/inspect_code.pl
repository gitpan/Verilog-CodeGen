#!/usr/bin/perl -w
use strict;

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

$current=~s/\.pl//;
chdir 'TestObj';


my @objs=`ls -1 -t *$current*.v`;
if(@objs>0) {
if($current ne '' ) {
print "Found ",@objs," files matching $current:\n";
foreach my $item (@objs) {
print "$item";
}
}
 $current=shift @objs;
chomp $current;
} 



print '-' x 60,"\n","\tConverting $current to HTML ...\n",'-' x 60,"\n";
if( $current=~/\.v/) {

#warn("v2html -njshier -ncookies -nsigpopup -o HTML $current");
#system("v2html -njshier -ncookies -nsigpopup -o HTML $current ");
  if (not -e "HTML") {
system("mkdir HTML");
}
system("v2html -o HTML $current ");
print '-' x 60,"\n","\tLaunching browser ...\n",'-' x 60,"\n";
#system("gnome-terminal -e 'lynx HTML/$current.html' &");
#dillo is very fast, but no CSS support :-(
#system("dillo  HTML/$current.html &");
system("galeon --geometry=400x600+10+10 HTML/$current.html &");


} else {
print "No such file \n";
}
print "\n ... Done\n";
