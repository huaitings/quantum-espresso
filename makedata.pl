use strict;
use warnings;
use Cwd;
my $currentPath = getcwd();
my @myelement = sort ("Co","Cr","Fe","Hf","Mn","Nb","Ni","Ta","Ti","Zr");
my $myelement = join ('',@myelement);

my $out_file = `find $currentPath/$myelement/Opt -name "*.sout"`;
my @out_file = split("\n", $out_file);
@out_file = sort @out_file;
my @out_filepath = map (($_ =~ m/(.*)\/\w*\.?\w*[+-]*\w+-\w+-\w+.sout$/gm),@out_file);
my @out_filename = map (($_ =~ m/(\w*\.?\w*[+-]*\w+-\w+-\w+).sout$/gm),@out_file);


my $running = `squeue -o \%j | awk 'NR!=1'`;
my @running = split("\n",$running);
my %running;
for(@running){
    $running{$_} = 1;
}

for my $id (0..$#out_file){


    my $done = `grep -o -a 'DONE' $out_file[$id]`; 
    chomp $done;
    if($done ne "DONE" ||  exists $running{$out_filename[$id]}){
        next;
    }
open my $all ,"< $out_file[$id]";
my @all = <$all>;
close($all);
my $natom = `cat $out_file[$id]|sed -n '/number of atoms\\/cell/p' | sed -n '\$p'| awk '{print \$5}'`;
chomp $natom;
if(!$natom){die "You don't get the Atom Number!!!\n $out_file[$id]";}
open my $data ,"> $out_filepath[$id]/$out_filename[$id].data";
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
my $element = `cat $out_file[$id] | sed -n -r '/^\\s+[A-Z][a-z]\\s+[0-9]+.[0-9]+\\s+/p' |awk '{print \$1}' | sort | uniq `;
my @element = split("\n",$element);
@element = sort @element;
my %element;
for (my $i=1; $i<=@element; $i++){
    my $r = $i-1;
    $element{$element[$r]}= $i;
}

my $mass = `cat $out_file[$id] | sed -n -r '/^\\s+[A-Z][a-z]\\s+[0-9]+.[0-9]+\\s+/p' |awk '{print \$3}' | sort | uniq `;
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
}
}


