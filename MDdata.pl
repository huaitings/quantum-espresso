#use strict;
#use warnings;
#use GD::Graph::lines; #折線圖
use GD::Graph::linespoints;	
use GD::Graph::Data;
use List::Util qw(max);
use List::Util qw(min);
#use List::Util;
use POSIX;
use Math::Trig;
use  Cwd;
my $path = getcwd();
my @output = `cat *.sout`;
#print @output;
`rm -rf output`;
`mkdir output`;
my @myelement = sort ("Al","Mo","Nb","Ta","Ti","Zr");
my $myelement = join ('',@myelement);


#\s+number\s+of\s+atoms\/cell\s+=\s+(\d+)
for(0..$#output){
   if($output[$_] =~ m/\s+number\s+of\s+atoms\/cell\s+=\s+(\d+)/g)
  {
    $atomscell = $1;
  }
     if($output[$_] =~ m/\s+nstep\s+=\s+(\d+)/g)
  {
    $nstep = $1;
  }
}
print $nstep;
@CELL_PARAMETERS = `grep -A3 "CELL_PARAMETERS (angstrom)" *.sout`;
for(0..$#CELL_PARAMETERS ){
   if($CELL_PARAMETERS [$_] =~ m/\s+(\-?\d+\.\d+)\s+(\-?\d+\.\d+)\s+(\-?\d+\.\d+)/g)
  {
    push @box,$1,$2,$3;
  }
}
@coord = `grep -A$atomscell "ATOMIC_POSITIONS (angstrom)" *.sout`;
for(0..$#coord){
    if($coord[$_] =~ m/(\w+)\s+(\-?\d+\.\d+\s+\-?\d+\.\d+\s+\-?\d+\.\d+)/g)
  {
   push @element,"$1";
   push @Cartcoord,"$2";
  }
}
my $k=-1;
my $j=-1;
my $s=0;
for(0..$#Cartcoord){
$k=$k+1;
push @newcoord,"$Cartcoord[$k]";
push @newelement,"$element[$k]";
  
#print "$alpha $beta $gamma\n";
#print "$A $B $C\n";


#print "$lz \n";
if(($k+1)%($atomscell)==0)
{
$j=$j+1;
#open $data ,">MD$j.data";

open $data ,">./output/MD$j.data";
#./output/PSOmaxdmol.dat"
#######################################
$A = sqrt(@box[9*$j]**2 + @box[9*$j+1]**2 + @box[9*$j+2]**2);
$B = sqrt(@box[9*$j+3]**2 + @box[9*$j+4]**2 + @box[9*$j+5]**2);
$C = sqrt(@box[9*$j+6]**2 + @box[9*$j+7]**2 + @box[9*$j+8]**2);
#print "$A $B $C\n";
$A_dot_B = @box[9*$j]*@box[9*$j+3] + @box[9*$j+1]*@box[9*$j+4] + @box[9*$j+2]*@box[9*$j+5];
$B_dot_C = @box[9*$j+3]*@box[9*$j+6] + @box[9*$j+4]*@box[9*$j+7] + @box[9*$j+5]*@box[9*$j+8];
$A_dot_C = @box[9*$j]*@box[9*$j+6] + @box[9*$j+1]*@box[9*$j+7] + @box[9*$j+2]*@box[9*$j+8];
#print "$A_dot_B $B_dot_C $A_dot_C\n";
$alpha = acos($B_dot_C / ($B*$C))*180/3.1415926535; #BC
$beta = acos($A_dot_C / ($A*$C))*180/3.1415926535; #AC
$gamma = acos($A_dot_B / ($A*$B))*180/3.1415926535; #AB
#print "$alpha $beta $gamma\n";
$lx = $A;
$xy = $B*cos($gamma*3.1415926535/180);
$xz = $C*cos($beta*3.1415926535/180);
$ly = sqrt($B**2 - ($xy)**2);
$yz = ($B*$C*cos($alpha*3.1415926535/180)-$xy*$xz)/$ly;
$lz = (($C**2) - ($xz**2) - ($yz**2))**0.5;
#print $B;
print "transfering MD$j.data into data file \n";
#print cos($gamma*3.1415926535/180);
#print "\n";
#print "$lx $ly $lz \n";
#######################################
print $data "LAMMPS data file via write_data, version 10 Mar 2021, timestep = 0\n\n";
print $data "$atomscell atoms\n";
print $data  "6  atom types\n\n";
print $data "0.0 $lx xlo xhi\n";
print $data "0.0 $ly ylo yhi\n";
print $data "0.0 $lz zlo zhi\n";
print $data "$xy $xz $yz	xy xz yz\n";
#print "$_\n";
#print "";
#print "@newelement";


my %mynewelement;
for (my $i=1; $i<=@myelement ; $i++){
    my $r = $i-1;
    $mynewelement{"$myelement[$r]"}= $i;
}
print $data "Atoms\n\n";
for (0..$atomscell-1){
  $number = $_+1;

print $data "$number"." $mynewelement{@newelement[$_]}"."  @newcoord[$_]\n";}
#print "\n";
@newcoord=();
@newelement=();
}
}

 @density = `cat *.sout |grep density`;
#print @density;
for(0..$#density){
     if($density[$_] =~ m/\s+density\s+=\s+(\d+\.\d+)\s+g\/cm\^3/g)
  {
    push @QEdensity,"$1\n";
  }
}
open $density ,">density.txt";
for(0..$nstep-1)
{
  $step = $_ + 1;
print $density "$step"." @QEdensity[$_]";}
system("perl lines.pl");
