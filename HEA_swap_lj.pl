# We will submit slrum in the local folder
use strict;
use warnings;
use POSIX;
use lib '.';
use HEA;
use Cwd; #Find Current Path
my $currentPath = getcwd(); #get perl code path

my @myelement = sort ("Hf","Nb","Ta","Ti","Zr");
my $myelement = join ('',@myelement);

my $data_file = `find $currentPath/$myelement/initial -name "out-*-*.data"`;
my @data_file = split("\n", $data_file);
@data_file = sort @data_file;
my @filename = map (($_ =~ m/out-(\w+-\w+).data/g),@data_file);

my $slurm = "yes"; # use slurm or not
my $slurmbatch = "slurm.sh"; # slurm batch template
my $lmp_path = "/opt/lammps/lmp_mpi_bigwind";
my $lmp_script = "swap.in";# lmp script, you may use different one for your purpose
my $swaptime = 200;# swap time for each run

my $eleNo = 5; #total element types
my $rmin = 2.63;
my $rc = 5;


# my $pair0 = "pair_coeff * * ../ref.lib Al0 Mo0 Nb0 Ta0 Ti0 Zr0 ../Bestfitted.meam Al0 Mo0 Nb0 Ta0 Ti0 Zr0";#for swap

# my $pair_coeff = "pair_coeff * * ../ref.lib Al Mo Nb Ta Ti Zr ../Bestfitted.meam Al Mo Nb Ta Ti Zr";

# Initial setting

my $folder2read = "initial"; #folder to read required files
my $folder2write = "$currentPath/$myelement/$folder2read-swap_lj"; #folder to write data
my $prefix2write = "swap"; #prefix of the output file
`mkdir -p $folder2write`; # create a new folder



#`sed -i '/#SBATCH.*--job-name/d' $currentPath/$slurmbatch`;
# `sed -i '/pair_coeff/d' $currentPath/$lmp_script`;
`sed -i 's:.*pair_style.*:pair_style lj/cut $rc:' $currentPath/$lmp_script`;
`sed -i '/pair_coeff.*/d' $currentPath/$lmp_script`;#remove all first
`sed -i '/.*atom\\/swap.*/d' $currentPath/$lmp_script`;#remove all first
`sed -i '/unfix.*/d' $currentPath/$lmp_script`;#remove all first
my $fixID = 100;
for (1..$eleNo){
	`sed -i '/pair_style/a pair_coeff $_ $_ 0 $rmin' $currentPath/$lmp_script`;
}


for my $id1 (1..$eleNo-1){
	for my $id2 ($id1+1..$eleNo){
		my $swaprand = POSIX::ceil(10000*rand());
		my $temp = "fix $fixID all atom\/swap 1 $swaptime $swaprand 300.0 ke no types $id1 $id2";
		`sed -i '/pair_style/a pair_coeff $id1 $id2 10  $rmin' $currentPath/$lmp_script`;
	    `sed -i '/thermo_style/a $temp' $currentPath/$lmp_script`;
	    `sed -i '/run.*/a unfix $fixID' $currentPath/$lmp_script`;
	    $fixID++;
	}	
}


## modify read_data and write_data according to the file path 


for my $id (0..$#data_file){
#	print "$_ \n";
	# /out-(.*).data/;
	# chomp;
	# chomp $1;
#	print "$1\n";
	my $read_data = "read_data $data_file[$id]";
	`sed -i 's:.*read_data.*:$read_data:' $lmp_script`;# modify atom type numbers for the system you want
	my $write_data = "write_data swap-$filename[$id].data pair ij";# in different folder from read in data
	`sed -i 's:.*write_data.*:$write_data:' $lmp_script`;# modify atom type numbers for the system you want
    `sed -i '/log/d' $lmp_script`;
    `sed -i '1i log none' $lmp_script`;
	`cp $lmp_script $folder2write/swap-$filename[$id].in`;

	`sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --job-name=swap-$filename[$id]' $slurmbatch`;

	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=swap-$filename[$id].sout' $slurmbatch`;

	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $lmp_path -l none -in $folder2write/swap-$filename[$id].in' $slurmbatch`;
	`cp $slurmbatch $folder2write/swap-$filename[$id].sh`;

	chdir("$folder2write");	
	system("sbatch swap-$filename[$id].sh");
	#system("/opt/lammps-mpich-3.4.1/lmp_20210329 -l none -in ../$lmp_script");
	chdir("$currentPath");
}

