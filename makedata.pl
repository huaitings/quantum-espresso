use strict;
use warnings;
use Cwd;
my $currentPath = getcwd();
my @myelement = sort ("Al","Mo","Nb","Ta","Ti","Zr");
my $myelement = join ('',@myelement);

my $out_file = `find $currentPath/$myelement/Opt -name "*.sout"`;
my @out_file = split("\n", $out_file);
@out_file = sort @out_file;
print @out_file;
for my $id (0..$#out_file){
open my $all ,"< $out_file[$id]";
my @all = <$all>;
close($all);
my $natom = `cat $out_file[$id]|sed -n '/number of atoms\\/cell/p' | sed -n '\$p'| awk '{print \$5}'`;
chomp $natom;
if(!$natom){die "You don't get the Atom Number!!!\n";}
my @dataname = map (($_ =~ m/(Opt-\w+-\w+)\.sout/g),$out_file[$id]);
open my $data ,"> ./$myelement/Opt/@dataname/@dataname.data";
print $data "LAMMPS data file via write_data, version 10 Mar 2021, timestep = 0\n";
for(@all){
    if(m/\s+number\s+of\s+atoms\/cell\s+\=\s+(\d+)/s){
        my $atom = $1;
        print $data "$atom atoms\n";
    }
    if(m/\s+number\s+of\s+atomic\s+types\s+\=\s+(\d+)/s){
        my $type =$1;
        print $data "$type atom types\n";
    }
}


my @box = grep {if(m/^\s{1,3}([-+]?\d+\.?\d+)\s+([-+]?\d+\.?\d+)\s+([-+]?\d+\.?\d+)$/){
$_ = [$1,$2,$3];}} @all;

my $databox1 = ( @{$box[-3]}[0]**2 + @{$box[-3]}[1]**2 + @{$box[-3]}[2]**2 )**0.5;
my $databox2 = ( @{$box[-2]}[0]**2 + @{$box[-2]}[1]**2 + @{$box[-2]}[2]**2 )**0.5;
my $databox3 = ( @{$box[-1]}[0]**2 + @{$box[-1]}[1]**2 + @{$box[-1]}[2]**2 )**0.5;
print $data "0 $databox1 xlo xhi\n";
print $data "0 $databox2 ylo yhi\n";
print $data "0 $databox3 zlo zhi\n";
print $data "@{$box[-3]}[1] @{$box[-3]}[2] @{$box[-2]}[2] xy xz yz\n";


print $data "Masses\n\n";
my $element = `cat $out_file[$id] | sed -n -r '/^\\s+[A-Z][a-z]\\s+[0-9]./p' | sort | uniq |awk '{print \$1}'`;
my @element = split("\n",$element);
@element = sort @element;
my %element;
for (my $i=1; $i<=@element; $i++){
    my $r = $i-1;
    $element{$element[$r]}= $i;
}

my $mass = `cat $out_file[$id] | sed -n -r '/^\\s+[A-Z][a-z]\\s+[0-9]./p' | sort | uniq |awk '{print \$3}'`;
my @mass = split("\n",$mass);
for (0..$#element){
    my $i = $_+1;
print $data "$i "."$mass[$_]\n";
}


my @coord = grep {if(m/^(\w+)\s+([-+]?\d+\.?\d+\s+[-+]?\d+\.?\d+\s+[-+]?\d+\.?\d+)$/gm){
$_ = [$1,$2];}} @all;
print $data "Atoms\n\n";
for(1..$natom){
print $data "$_ "."$element{$coord[-$_][0]}\t"."$coord[-$_][1]\n";
# print $element{" @{$mass[$_ -1]}[0]"};
}
}


#my @mass = grep {if(m/\s+\w*\s+\d*\.\d*\s+\d*\.\d*\s+\w*\(\s+\d+\.\d+\)/){$_ = $1,$2;}} @all;
#print @mass[1];
#for (0..$#mass){
#print "$mass[$_]\n";
#print "\n" if ($_ ne $#mass);



#@CELL_PARAMETERS = `grep -A1 -A4 "CELL_PARAMETERS" *.out`;
#for(0..$#CELL_PARAMETERS){
# if($CELL_PARAMETERS[$_] =~ m/(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+.\d+)/g)#cell
# {
# push @lattice,$1,$2,$3;
# }
#}
#@brav1 = ((@lattice[0])**2 + (@lattice[1])**2 + (@lattice[2])**2)**0.5;
#@brav2 = ((@lattice[3])**2 + (@lattice[4])**2 + (@lattice[5])**2)**0.5;
#@brav3 = ((@lattice[6])**2 + (@lattice[7])**2 + (@lattice[8])**2)**0.5;
#print @ibrav1
