#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002 Wim Vanderbauwhede. All rights reserved.                  #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

use strict;
use Cwd;
use Tk;
my $xe=1;
if(@ARGV&&$ARGV[0] eq '-nox'){
 $xe=0;
}
print STDERR "Starting UI ...";

my $normal='-adobe-helvetica-medium-r-normal-*-12-*-*-*-*-*-iso8859-1';
my $bold='-adobe-helvetica-bold-r-normal-*-12-*-*-*-*-*-iso8859-1';
my $console='-misc-fixed-bold-r-normal-*-*-140-*-*-c-*-iso8859-1';
my @matrix;
#-------------------------------------------------------------------
my $xemacs=0;
my $debug=0;
my $update=0;
my $overwrite=0;
my $showtb=0;
my $showdefault=0;
my $text;
my $nlines=20;
my $nowarn=0;
my $plot=0;
my $run=1;
my $inspectcode=0;
my $pid='WRONG';
my $selectedfile='NONE';
&create_ui();
&launch_xemacs($xe);

=for_named_pipe
use Fcntl;
my $path='tmp';
if(-e $path){unlink $path}
require POSIX;
POSIX::mkfifo($path,0666) or die $!;
=cut

print STDERR "\nDone \n";
print STDERR "\nCreating socket ... \n";
use IO::Socket;
my $new_sock;
my $buff;
my $i=0;
my $ok=1;
my $sock = new IO::Socket::INET (LocalHost => 'localhost',
				 LocalPort => 2507,
				 Proto => 'tcp',
				 Listen => 5,
				 ReuseAddr => 1,
				 );
die "Could not connect: $!" unless $sock;
print STDERR "Done \n";

MainLoop();

exit(0);


#-------------------------------------------------------------------
sub create_ui {
    my $top = MainWindow->new('-background'=>'white','-title'=>'Perl/Verilog Coding Environment');

    # MENU STUFF

    # Menu bar
    my $menu_bar_frame = $top->Frame('-background'=>'darkgrey','-width'=>80)->pack('-side' => 'top','-anchor'=>'w', '-fill' => 'x');
my $menu_bar=$menu_bar_frame->Frame('-background'=>'grey','-relief'=>'flat','-borderwidth'=>1,'-width'=>80)->pack('-side' => 'left','-anchor'=>'w', '-fill' => 'x','padx'=>5,'pady'=>5);
#==============================================================================

# General 
    # File menu
    my $menu_file = $menu_bar->Menubutton('-text' => 'File','-tearoff'=>0,
                                          '-relief' => 'flat',
                                          '-borderwidth' => 1,'font'=>$normal,'foreground'=>'black','background'=>'grey'
                                          )->grid('-row'=>0,'-column'=>0,'-sticky'=>'w','-pady'=>5,'-padx'=>5);

    $menu_file->command('-label' => 'XEmacs', '-state'=>'active',
			'-command' => sub {$xemacs=1;system("xemacs blank &")},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'Schematics', '-state'=>'active',
			'-command' => sub {chdir 'Schematics';system("tkgate &"); chdir '..'},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'Diagrams', '-state'=>'active',
			'-command' => sub {chdir 'Diagrams';system("dia &"); chdir '..'},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'gCVS', '-state'=>'active',
			'-command' => sub {system("/usr/local/gcvs/bin/gcvs &")},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'Exit', '-command' => sub {close $sock;if($pid ne 'WRONG'){exec("kill -9 $pid")}else{exit(0)}},'foreground'=>'black','background'=>'grey','font'=>$normal,);

#==============================================================================

 $matrix[0][3] = $menu_bar->Label ('background' =>'grey')->grid('-row'=>0,'-column'=>3,'-sticky'=>'w',);

my $image=  $matrix[0][3]->Photo('-file'=>'GUI/rectangle_power_perl.gif');
 $matrix[0][3]->configure('-image'=>$image);


#==============================================================================
    # Device Object Code
 $matrix[1][0] = $menu_bar->Label ('-text'=>'Device Object Code', '-width'=>80, '-font' => $bold,'foreground' => 'black', '-background' =>'lightgrey',)->grid(
'-row' => 1, '-column' => 0,'-columnspan'=>4,'-sticky'=>'w');

 $matrix[2][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Edit', '-command' => \&show_obj)->grid(
'-row' => 2,'-column'=> 3,'-sticky'=>'w');
 $matrix[2][2] = $menu_bar->Entry ('-width'   =>  20, '-font' => $normal,'foreground' => 'black','background' =>'white', )->grid(
'-row' => 2, '-column' => 2);

 $matrix[3][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Parse', '-command' => \&debug)->grid(
'-row' => 3,'-column'=> 3,'-sticky'=>'w');

 $matrix[3][1] = $menu_bar->Label ('-text'=>'Show result', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w')->grid(
'-row' => 3, '-column' =>1,'-sticky'=>'w');
 $matrix[3][0] = $menu_bar->Checkbutton ('-variable'   => \$showdefault,
 '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0)->grid(
'-row' => 3, '-column' =>0,'-sticky'=>'e');
#==============================================================================
    # Device Library Module
 $matrix[4][0] = $menu_bar->Label ('-text'=>'Device Library Module', '-width' => 80, '-font' => $bold,'foreground' => 'black','background' =>'lightgrey',)->grid(
'-row' => 4, '-column' => 0,'-columnspan'=>4,'-sticky'=>'w');

 $matrix[5][0] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Update', '-command' => \&update)->grid(
'-row' => 5,'-column'=>3,'-sticky'=>'w');

 $matrix[5][1] = $menu_bar->Label ('-text'=>'Show module', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w')->grid(
'-row' => 5, '-column' =>1,'-sticky'=>'w');
 $matrix[5][3] = $menu_bar->Checkbutton ('-variable'   => \$update,
 '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0)->grid(
'-row' => 5, '-column' =>0,'-sticky'=>'e');

#==============================================================================
    # Testbench Code
 $matrix[6][0] = $menu_bar->Label ('-text'=>'Testbench Code', '-width' => 80, '-font' => $bold,'foreground' => 'black','background' =>'lightgrey',)->grid(
'-row' => 6, '-column' => 0,'-columnspan'=>4);
#------------------------------------------------------------------------------
 $matrix[7][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Edit', '-command' => \&show_tb)->grid(
'-row' => 7 ,'-column'=>3,'-sticky'=>'w');
 $matrix[7][2] = $menu_bar->Entry ('-width'   =>  20, '-font' => $normal,'foreground' => 'black','background' =>'white',)->grid(
'-row' => 7, '-column' =>2);
 $matrix[7][1] = $menu_bar->Label ('-text'=>'Overwrite', '-font' => $bold,'foreground' => 'black','background' =>'grey', '-width'=> 20, '-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 7, '-column' =>1,'-sticky'=>'w');
 $matrix[7][0] = $menu_bar->Checkbutton ('-variable'   => \$overwrite, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width' => 0)->grid(
'-row' => 7, '-column' =>0,'-sticky'=>'e');
#------------------------------------------------------------------------------
 $matrix[8][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Parse', '-command' => \&run_tb )->grid(
'-row' => 8 ,'-column'=>3,'-sticky'=>'w');

 $matrix[8][1] = $menu_bar->Label ('-text'=>'Show result', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 8, '-column' =>1,'-sticky'=>'w');
 $matrix[8][0] = $menu_bar->Checkbutton ('-variable'   => \$showtb, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 8, '-column' =>0,'-sticky'=>'e');

 $matrix[9][1] = $menu_bar->Label ('-text'=>'Inspect Code', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 9, '-column' =>1,'-sticky'=>'w');
 $matrix[9][0] = $menu_bar->Checkbutton ('-variable'   => \$inspectcode, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 9, '-column' =>0,'-sticky'=>'e');

 $matrix[10][1] = $menu_bar->Label ('-text'=>'Plot', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 10, '-column' =>1,'-sticky'=>'w');
 $matrix[10][0] = $menu_bar->Checkbutton ('-variable'   => \$plot, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 10, '-column' =>0,'-sticky'=>'e');

 $matrix[11][1] = $menu_bar->Label ('-text'=>'Run','-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 11, '-column' =>1,'-sticky'=>'w');
 $matrix[11][0] = $menu_bar->Checkbutton ('-variable'   => \$run,'-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 11, '-column' =>0,'-sticky'=>'e');

=no_warnings
 $matrix[10][1] = $menu_bar->Label ('-text'=>'No warnings', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 10, '-column' =>1,'-sticky'=>'w');
 $matrix[10][0] = $menu_bar->Checkbutton ('-variable'   => \$nowarn, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 10, '-column' =>0,'-sticky'=>'e');
=cut
#------------------------------------------------------------------------------
 $matrix[12][0] = $menu_bar->Label ('-text'=>'Output log', '-width' => 80, '-font' => $bold,'foreground' => 'black','background' =>'lightgrey',)->grid(
'-row' => 12, '-column' => 0,'-columnspan'=>4);
#==============================================================================
# Console 
my $text_frame = $top->Frame('-background'=>'black', '-width'=>80)->pack('-side' => 'top', '-fill' => 'x');
#
 $text=$text_frame->Text('-foreground' => 'grey','-background'=>'black','-height'=>25, '-width'=>80)->pack('-side' => 'left', '-fill' => 'y');
 $text->tagConfigure('console', '-font' => $console,'foreground' => 'grey','background' =>'black',); 
my $scroll=$text_frame->Scrollbar('-background'=>'grey','-width'=>10,'-command' => ['yview', $text])->pack('-side' => 'right', '-fill' => 'y');
# Inform listbox about the scrollbar
$text->configure('-yscrollcommand' => ['set', $scroll]);

  } #end of create_ui
#-------------------------------------------------------------------
sub launch_xemacs {
my $xe=shift;
if($xe) {
# we could do fork & exec, but this is more intuitive
system("xemacs blank&");
my @pid=`ps -aux | grep 'xemacs blank' | grep -v grep`;
$pid=shift @pid;
chomp $pid;
$pid=~s/^\w+\s+(\d+)/$1/;
$pid=~s/\s+.*//;
}
}
#-------------------------------------------------------------------
sub show_obj {
my $pattern= $matrix[2][2]->get();
system("./GUI/debug.pl -s $pattern 2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/debug.pl -s $pattern > tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub debug {
  (!$showdefault)&&($showdefault=0);
my $pattern= $matrix[2][2]->get();
my $f='';
if ($showdefault==1) {$f='-sd'}
system("./GUI/debug.pl $f $pattern 2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/debug.pl $f $pattern >& tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub update {
  (!$update) &&($update=0);
my $f='';
if($update==1){$f='-s'}
$text->delete('1.0','end');
system("./GUI/update.pl $f  2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/update.pl $f >& tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub show_tb {
my $pattern= $matrix[7][2]->get();
my $f='';
if($overwrite==1){$f='-f'}
system("./GUI/test.pl $f $pattern  2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/test.pl $f $pattern >& tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub run_tb {

my $pattern= $matrix[7][2]->get();
my $p='-off';
my $r='-off';
if($plot){$p='-on'}
if($run){$r='-on'}
my $f='-r';
if($showtb==1){$f='-rs'}
system("./GUI/test.pl $f $p $r $pattern  2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/test.pl $f $pattern >& tmp &");
#&write_output();
if($inspectcode==1) {
system("./GUI/inspect_code.pl $pattern &");#2>&1 | ./GUI/send_stdout.pl &");
#&listen();
}
}
#-------------------------------------------------------------------
=for_fifo
sub write_output {
  if(!$nowarn){$nowarn=0}
  $text->delete('1.0','end');

sysopen(FIFO,$path,O_RDONLY)  or die $!;
 my $i=0;
while(<FIFO>){

($nowarn==1) && /\.v\:/ && next;

    $i++;
    $text->insert("$i.0",$_);
    $text->tagAdd('console','1.0','end');
}
close FIFO;
select(undef,undef,undef,0.2);

}
=cut
#-------------------------------------------------------------------
=if_all_else_fails
sub write_output_old {
  if(!$nowarn){$nowarn=0}
  $text->delete('1.0','end');

  open(TMP,"<tmp");
  my $i=0;
  while(<TMP>){
($nowarn==1) && /\.v\:/ && next;

    $i++;
    $text->insert("$i.0",$_);
    $text->tagAdd('console','1.0','end');
  }
  close TMP;
}
=cut
#-------------------------------------------------------------------
sub listen {

  if(!$nowarn){$nowarn=0}
  $text->delete('1.0','end');


$new_sock = $sock->accept();

  while (defined ( $buff =<$new_sock>)) {

$_=$buff;
($nowarn==1) && /\.v\:/ && next;
if(!/testbench/ && /Parsing/ && /\.pl/){
$selectedfile=$_;
chomp $selectedfile;
$selectedfile=~s/^\s*Parsing\s+//;
$selectedfile=~s/\s+.*$//;
#$matrix[2][2]->selectionFrom(0);
#$matrix[2][2]->selectionTo(30);
$matrix[2][2]->delete(0,'end');
 $matrix[2][2]->insert(0,$selectedfile);
} elsif (/test_.*testbench/) {
$selectedfile=$_;
chomp $selectedfile;
$selectedfile=~s/^.*test_/test_/;
$selectedfile=~s/\s+.*$//;
$matrix[7][2]->delete(0,'end');
 $matrix[7][2]->insert(0,$selectedfile);
}
    $i++;
    $text->insert("$i.0",$_);
    $text->tagAdd('console','1.0','end');
}

}
