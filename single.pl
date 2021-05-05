use strict;
use warnings;
use POSIX;
use lib '.';
use HEA;
use Cwd; #Find Current Path

my $currentPath = getcwd(); #get perl code path

# Initial setting
my $slurmbatch = "slurm.sh"; # slurm batch template
my $lmp_path = "/opt/lammps/lmp_mpi_bigwind";
my @myelement = sort ("Co","Cr","Fe","Hf","Mn","Nb","Ni","Ta","Ti","Zr");
my $foldername = "$currentPath/".join("",@myelement)."/single"; #folder to keep all generated files
`mkdir -p $foldername`; # create a new folder
my $lmp_in = "singledensity.in";
my $lmp_data = "atomsk.lmp";
my $eleNo = @myelement;
print "The following are all elements you want to use:\n\n";    

my %myelement;# for keep an array with all element information
for (@myelement){
    chomp;
     @{$myelement{$_}} = &HEA::eleObj("$_");
    print "element: $_, properties: @{$myelement{$_}}\n";    
}
for (my $i=0; $i<$eleNo ; $i++){
unlink "./$lmp_data";
my $structure = ${$myelement{$myelement[$i]}}[1];
my $a= ${$myelement{$myelement[$i]}}[3];
my $c =${$myelement{$myelement[$i]}}[4];
my $crystal = "$structure $a $myelement[$i]" ;
$crystal = "$structure $a $c $myelement[$i]" if ($structure eq "hcp");
my $orient = "[100] [010] [001]";# crystal axis vectors
my $dup = "2 2 2";
my $type1 = $i+1;
my $atomsk = "atomsk --create $crystal orient $orient -dup $dup $lmp_data";
$atomsk ="atomsk --create $crystal -dup $dup $lmp_data" if($structure eq "hcp");
# # end of initial setting

`$atomsk`;
`sed -i 's:.*atom types.*:$eleNo atom types:' $lmp_data`;# modify atom type numbers for the system you want
`sed -i '/Masses/,/Atoms/{/Masses/!{/Atoms/!d}}' $lmp_data`;#remove lines between two key words

for (reverse 1..@myelement){# for lammps type ID starting from 1
	my $ele = $myelement[$_ - 1];# for Perl array ID starting from 0
	system("sed -i '/Masses/a $_ ${$myelement{$ele}}[2]' $lmp_data");# append something after the line with the key word
}
`sed -i '/Masses/G' $lmp_data`;# insert newline after the keyword
`sed -i 's/Atoms/\\n&/' $lmp_data`;# insert newline before the matched keyword (& or \0) 

####### end of modify lmp data file

	my $den =${$myelement{$myelement[$i]}}[0];
	my $var_den = "variable den_out equal $den";
	`sed -i 's:.*variable den_out equal.*:$var_den:' $lmp_in`;
	`sed -i '/set group/d' $currentPath/$lmp_in`;#remove all first
	`sed -i '/group type1.*/a set group type1 type $type1' $currentPath/$lmp_in`;
	`cp $lmp_in $foldername/$myelement[$i].in`;
	`cp $lmp_data $foldername/in_$myelement[$i].data`;

	my $read_data = "read_data in_$myelement[$i].data";
	`sed -i 's:.*read_data.*:$read_data:' $foldername/$myelement[$i].in`;# modify atom type numbers for the system you want
	my $write_data = "write_data out-$structure-$myelement[$i].data";
	`sed -i 's:.*write_data.*:$write_data:' $foldername/$myelement[$i].in`;# modify atom type numbers for the system you want
    `sed -i '/log/d' $foldername/$myelement[$i].in`;
    `sed -i '1i log none' $foldername/$myelement[$i].in`; # no log from lammps



	`sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;

 	`sed -i '/#sed_anchor01/a #SBATCH --job-name=$myelement[$i]' $slurmbatch`;

	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=$myelement[$i].sout' $slurmbatch`;

	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $lmp_path -l none -in $myelement[$i].in' $slurmbatch`;

 	`cp $slurmbatch $foldername/$myelement[$i].sh`;

	chdir("$foldername");
	system("sbatch $myelement[$i].sh");
	chdir("$currentPath");
	
}

