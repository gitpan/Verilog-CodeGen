#!/usr/bin/perl -w
use strict;
use Cwd;
### -Creates a testbench if none exists 
### -Otherwise runs the testbench
### -Some useful flags would be:
###       -Create without checking: -f
###       -Provide list of parameters: -p


my $current='';
my $f=0;
my $s=0;
my $r=0;
my $run=1;
my $p=0;
if(@ARGV){
$current=$ARGV[0];
}
if($current eq '-f') {
$current=$ARGV[1]||'';
$s=0;
$f=1;
}
if($current eq '-s') {
$current=$ARGV[1]||'';
$f=0;
$s=1;
}
if($current eq '-r') {
$current=$ARGV[3]||'';
$f=0;
$s=0;
$r=1;
if($ARGV[1] eq '-on'){$p=1}
if($ARGV[2] eq '-off'){$run=0}
}
if($current eq '-rs') {
$current=$ARGV[3]||'';
$f=0;
$s=1;
$r=1;
if($ARGV[1] eq '-on'){$p=1}
if($ARGV[2] eq '-off'){$run=0}
}

#===============================================================================
#
# Get the perl object file 
#

chdir 'DeviceLibs/Objects';

my @objs=();
if($current=~/test_.*\.pl/){
push @objs,$current;
} else {
$current=~s/test_//;
@objs=`ls -1 -t *$current*.pl`;
}

if(@objs>0) {
if($current ne '') {
print "Found ",scalar(@objs)," file(s) matching $current:\n";
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

$current=~s/\.pl//;
$current=~s/test_//;

my $tb_template='';
if ($f or (not -e "../../TestObj/test_$current.pl")) {
print '-' x 60,"\n","\tCreating test_$current testbench ...\n",'-' x 60,"\n";

my $paramlist='';
my @paramlist=`egrep -e '\=\ *.objref->' $current.pl`;
my %par0val=();
foreach  (@paramlist) {
chomp ;
/^\#|modulename|pins/ && next;
s/^.*{//;
s/}\s*\|\|\s*/=>/;
s/\;.*$//;
my $par0tmp=$_;
my ($par0key,$par0val)=split('=>',$par0tmp);
if($par0key=~/^n/){

$par0val{"${par0key}0"}=$par0val-1;
}
$paramlist.="$_,";

}

my $par0list='';
my $outputs='';
my $regs='';
my $assigns='';
my @pins=`egrep -e 'parameter|input|output|inout' ../../TestObj/${current}_default.v`;
foreach  (@pins) {
  s/\/\/.*$//;
  if(/output/) {
    my $out=$_;
    chomp $out;
    $out=~s/output\s+//;
    $out=~s/\[.*\]\s+//;
    $out=~s/;.*$//;
    $outputs.=",$out";
  } # if output
  if(/input/) {
    # use to create registers
    my $in=$_;
    chomp $in;
    $in=lc($in);
    $in=~s/input\s+/reg /;
    $regs.="$in\n";
    my $inps=$in;
    $inps=~s/reg\ //;
    $inps=~s/\s*;.*//;
    my @regs=split(',',$inps);
    foreach my $reg (@regs) {
$reg=~s/\[.*\]//;
      my $inp=uc($reg);
      $assigns.="assign $inp=$reg;\n";
    }
  } # if input
s/input|output|inout/wire/;

} # foreach pin
my $pinlist=join('',@pins);

my $b='';
$outputs=~s/^\,//;
my @outputs=split(/\,/,$outputs);
 $outputs='';
my $title='';
foreach my $out (@outputs) {
# build the $display line
$b.=' \%b';
$outputs.=',$x.'.$out;
$title.=" $out";
}

$tb_template='#!/usr/bin/perl -w
use strict;
use lib "..";

use DeviceLibs::Verilog;

################################################################################

my $device=new("'.$current.'",'.$paramlist.');

open (VER,">test_'.$current.'.v");

output(*VER);

modules();

print VER "
module test_'.$current.';
'.$pinlist.'
'.$regs.'
'.$assigns.'
reg _ck;
";
$device->instance();
my $x=$device->{""};

print VER "
// clock generator
always begin: clock_wave
   #10 _ck = 0;
   #10 _ck = 1;

end

always @(posedge _ck)
begin
\$display(\" \%0d '.$b.' \",\$time'.$outputs.');
end

initial 
begin
\$display(\"Time '.$title.'\");

//      \$dumpfile(\"test_'.$current.'.vcd\");
//      \$dumpvars(2,test_'.$current.');

#25;

\$finish;
end
endmodule
";
close VER;
run("test_'.$current.'.v");
#plot("test_'.$current.'.v");

';
} # created testbench
chdir "../..";
chdir "TestObj";
if ($f or (not -e "test_$current.pl")) {
open(TB,">test_$current.pl");
print TB $tb_template;
close TB;
} 
  if($s) {
system("gnuclient test_$current.v &");
  }
  if($r) {
print "\n",'-' x 60,"\n","\tParsing test_$current.pl testbench ...\n",'-' x 60,"\n";
if($run) {#run
if ($p) {# plot
system("perl -p -i -e 'if(/dump/){s/^\\/+//};s/^\\#plot/plot/;s/^\\#run/run/;' test_$current.pl");
} else {# no plot
system("perl -p -i -e 'if(/dump/){s/^/\\/\\//};s/^plot/\\#plot/;s/^\\#run/run/;' test_$current.pl");
}
} else {#don't run
system("perl -p -i -e 'if(/dump/){s/^/\\/\\//};s/^plot/\\#plot/;s/^run/\\#run/;' test_$current.pl");
}
exec("perl test_$current.pl");
}

  if(!$s && !$r) {
print '-' x 60,"\n","\tDisplaying test_$current.pl testbench ...\n",'-' x 60,"\n";
system("gnuclient -q test_$current.pl &");
}

print "\n ... Done\n";
