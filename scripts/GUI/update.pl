#!/usr/bin/perl -w
use strict;

chdir 'DeviceLibs/Objects';
my $show=0;

if(@ARGV){
$show=$ARGV[0];
}
if($show eq '-s') {
$show=1;
}

print '-' x 60,"\n","\tUpdating Verilog.pm ...\n",'-' x 60,"\n";
system("perl make_module.pl &");
if($show==1){
chdir '..';
exec("gnuclient  Verilog.pm &");
}
print "\n ... Done\n";
