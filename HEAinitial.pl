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
my @myelement = sort ("Co","Cr","Fe","Mn","Ni");
my @assignfraction = map {$_ = 1;} 0..$#myelement;# assigned fractions for ch element
my $assignfraction = "yes";# use assign fraction
my $genNo = 10;# the total structures with random fractions you want to generate 
$genNo = 1 if ($assignfraction eq "yes");# only one struture for assigned fraction
my $foldername = "$currentPath/".join("",@myelement)."/initial"; #folder to keep all generated files
`mkdir -p $foldername`; # create a new folder
my $lmp_in = "density.in";
my $lmp_data = "atomsk.lmp";# atomsk output file for lmp data file
my $structure = "fcc";
my $crystal = "$structure 3.597 Ta";# crystal information
my $orient = "[100] [010] [001]";# crystal axis vectors
my $dup = "3 3 3";
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


# adjust elemnt fraction randomly
my $atomNo = `sed -n '/atoms/p' $lmp_data | awk '{print \$1}'`;# get the atom number from a data file 
for (1..$genNo){
	my @rand;
	for (0..$#myelement){push @rand, rand();}
	@rand = @assignfraction if ($assignfraction eq "yes");
	my $tempsum = 0.0;
	#print "@rand\n";
	for (@rand){$tempsum += $_;}
	map { $_ /= $tempsum } @rand;
	my @index_beg;
	my @index_end;
	my $temp = 0.0;


	for (@rand){
		$temp += $_;
		my $temp1 = POSIX::ceil($temp*$atomNo);
		push @index_end, $temp1;
	}

	$index_end[-1] = $atomNo;# the end atom ID
	$index_beg[0] = 1;# from 1 for lammps

	for (1..$#myelement){
		$index_beg[$_] = $index_end[$_ - 1] + 1;	
	}
	chomp (@index_beg,@index_end);
	my $index_beg = "variable beg index ". join(" ",@index_beg);
	my $index_end = "variable end index ". join(" ",@index_end);
	my $index_atomtype = "variable atomtype index ". join(" ",1..@myelement);


	`sed -i 's:.*variable beg index.*:$index_beg:' $lmp_in`;# modify atom type numbers for the system you want
	`sed -i 's:.*variable end index.*:$index_end:' $lmp_in`;# modify atom type numbers for the system you want
	`sed -i 's:.*variable atomtype index.*:$index_atomtype:' $lmp_in`;# modify atom type numbers for the system you want

	my %recipe;# use for lmp file prefix
	my $den_in = 0.0;
	for (0..$#myelement){
		$den_in += $rand[$_] * ${$myelement{$myelement[$_]}}[0];# density
		$recipe{$myelement[$_]} = POSIX::ceil($rand[$_]*100.);# element key to number (total 100)
	}
	my $var_den = "variable den_out equal $den_in";
	`sed -i 's:.*variable den_out equal.*:$var_den:' $lmp_in`;# modify atom type numbers for the system you want
	my $prefix;
	for (0..$#myelement){
		my $temp = sprintf("%02d",$recipe{$myelement[$_]});
		$prefix .= "$myelement[$_]"."$temp";
	}

	`cp $lmp_in $foldername/$structure-$prefix.in`;

	`cp $lmp_data $foldername/in_$structure-$prefix.data`;

	my $read_data = "read_data in_$structure-$prefix.data";
	`sed -i 's:.*read_data.*:$read_data:' $foldername/$structure-$prefix.in`;# modify atom type numbers for the system you want
	my $write_data = "write_data out-$structure-$prefix.data";
	`sed -i 's:.*write_data.*:$write_data:' $foldername/$structure-$prefix.in`;# modify atom type numbers for the system you want
    `sed -i '/log/d' $foldername/$structure-$prefix.in`;

    `sed -i '1i log none' $foldername/$structure-$prefix.in`; # no log from lammps

    

### making slurm batch files

    `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --job-name=$structure-$prefix' $slurmbatch`;
	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=$structure-$prefix.sout' $slurmbatch`;

	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $lmp_path -l none -in $structure-$prefix.in' $slurmbatch`;


	`cp $slurmbatch $foldername/$structure-$prefix.sh`;

	chdir("$foldername");	
	system("sbatch $structure-$prefix.sh");
	chdir("$currentPath");

}

