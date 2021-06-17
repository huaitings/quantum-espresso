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
# my @assignfraction = map {$_ = 1;} 0..$#myelement;# assigned fractions for each element
# my $assignfraction = "no";# use assign fraction
my $genNo = 30;# the total structures with random fractions you want to generate 
# $genNo = 1 if ($assignfraction eq "yes");# only one struture for assigned fraction
my $foldername = "$currentPath/".join("",@myelement)."/data/binary"; #folder to keep all generated files
`mkdir -p $foldername`; # create a new folder
my $lmp_in ="bidensity.in";
my $lmp_data = "atomsk.lmp";# atomsk output file for lmp data file
my $structure = "fcc";
my $structure_name = "B1";
my $crystal ="$structure 5 Ta Ti";# crystal information
my $orient = "[100] [010] [001]";# crystal axis vectors
my $dup = "1 1 1";
# end of initial setting
my %myelement;# for keep an array with all element information
print "The following are all elements you want to use:\n\n";    
for (@myelement){
    chomp;
     @{$myelement{$_}} = &HEA::eleObj("$_");
    print "element: $_, properties: @{$myelement{$_}}\n";    
}

## Begin modify lmp data file by sed
unlink "./$lmp_data";# remove old atomsk data file
#system("atomsk --create fcc 3.597 Cu orient [110] [-110] [001] -dup 3 3 3 template.lmp");
`atomsk --create $crystal orient $orient -dup $dup $lmp_data`;
my $eleNo = @myelement;# the element types in the system you want
`sed -i 's:.*atom types.*:$eleNo atom types:' $lmp_data`;# modify atom type numbers for the system you want
`sed -i '/Masses/,/Atoms/{/Masses/!{/Atoms/!d}}' $lmp_data`;#remove lines between two key words
for (reverse 1..@myelement){# for lammps type ID starting from 1
	my $ele = $myelement[$_ - 1];# for Perl array ID starting from 0
	system("sed -i '/Masses/a $_ ${$myelement{$ele}}[2]' $lmp_data");# append something after the line with the key word
}
`sed -i '/Masses/G' $lmp_data`;# insert newline after the keyword
`sed -i 's/Atoms/\\n&/' $lmp_data`;# insert newline before the matched keyword (& or \0) 
####### end of modify lmp data file

for (my $ipair1 =0 ; $ipair1 < $eleNo; $ipair1++) {
	my $lmpt1 = $myelement[$ipair1];
	for (my $ipair2 =1; $ipair2 <$eleNo; $ipair2++){
		my $eval = $ipair1-$ipair2;
		if($eval <0.0){
			my $lmpt2 = $myelement[$ipair2];

		my $bi_den =(${$myelement{$myelement[$ipair1]}}[0] + ${$myelement{$myelement[$ipair2]}}[0]) / 2;
		my $var_bi_den = "variable den_out equal $bi_den";
		my $type1 = $ipair1+1;
		my $type2 = $ipair2+1;
		`sed -i '/set group/d' $currentPath/$lmp_in`;#remove all first
		`sed -i 's:.*variable den_out equal.*:$var_bi_den:' $lmp_in`;
		`sed -i '/group type2.*/a set group type1 type $type1' $currentPath/$lmp_in`;
		`sed -i '/group type2.*/a set group type2 type $type2' $currentPath/$lmp_in`;
		my $bi_prefix = "$structure_name-"."$myelement[$ipair1]"."$myelement[$ipair2]";
		`cp $lmp_in $foldername/$bi_prefix.in`;
		`cp $lmp_data $foldername/in_"$bi_prefix".data`;

	my $read_data = "read_data in_$bi_prefix.data";
	`sed -i 's:.*read_data.*:$read_data:' $foldername/$bi_prefix.in`;# modify atom type numbers for the system you want
	my $write_data = "write_data out-$bi_prefix.data";
	`sed -i 's:.*write_data.*:$write_data:' $foldername/$bi_prefix.in`;# modify atom type numbers for the system you want
    `sed -i '/log/d' $foldername/$bi_prefix.in`;
    `sed -i '1i log none' $foldername/$bi_prefix.in`; # no log from lammps

	     `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;

 	`sed -i '/#sed_anchor01/a #SBATCH --job-name=$bi_prefix' $slurmbatch`;
	
	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=$bi_prefix.sout' $slurmbatch`;


	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $lmp_path -l none -in $bi_prefix.in' $slurmbatch`;


 	`cp $slurmbatch $foldername/$bi_prefix.sh`;

	
	chdir("$foldername");	
	system("sbatch $bi_prefix.sh");
	chdir("$currentPath");
		}
	}	
}
