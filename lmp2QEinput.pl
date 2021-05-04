use strict;
use warnings;
use JSON::PP;
use Data::Dumper;

use POSIX;
use lib '.';
use HEA;
use Cwd;
#########################################Set################################################
my $currentPath = getcwd();
my $pressure_set = "0"; #pressure
my $slurmbatch = "QE_slurmOpt.sh"; #slurm filename
my $lmp_path = "/opt/lammps/lmp_mpi_bigwind";
my $QE_path = "/opt/QEGCC_MPICH3.3.2/bin/pw.x";
my @myelement = sort ("Al","Mo","Nb","Ta","Ti","Zr");
my $elementname = "./".join("", @myelement);
my $foldername = "$elementname"."/Opt";
`mkdir -p $foldername`;
########################################json##########################################
my $json;
{
    local $/ = undef;
    open my $fh, '<', '/opt/QEpot/SSSP_efficiency.json';
    $json = <$fh>;
    close $fh;
}

my $decoded = decode_json($json);

# my @rho_cutoff;
# my @cutoff;
# for (@myelement){
#  push @rho_cutoff,$decoded->{$_}->{rho_cutoff};
#  push @cutoff,$decoded->{$_}->{cutoff};
# }
# my @rho_cutoff_sort = sort {$a<=>$b} @rho_cutoff;

#########################################HEA.pm#######################################
my %myelement;
for (@myelement){
    chomp;
     @{$myelement{$_}} = &HEA::eleObj("$_"); 
}
################################################
my $datafile = `find $elementname -name "*-*-*.data"`;
my @datafile = split("\n",$datafile);
@datafile = sort @datafile;
my @filename = map (($_ =~ m/(\w+.\w+).data/g),@datafile);

`sed -i '/ATOMIC_SPECIES/,/ATOMIC_POSITIONS {angstrom}/{/ATOMIC_SPECIES/!{/ATOMIC_POSITIONS {angstrom}/!d}}' $currentPath/Optimize.in`;
`sed -i '/ATOMIC_POSITIONS {angstrom/,/CELL_PARAMETERS {angstrom}/{/ATOMIC_POSITIONS {angstrom}/!{/CELL_PARAMETERS {angstrom}/!d}}' $currentPath/Optimize.in`;
`sed -i '/CELL_PARAMETERS {angstrom}/,/#End/{/CELL_PARAMETERS {angstrom}/!{/#End/!d}}' $currentPath/Optimize.in`;
 ###ATOMIC_SPECIES###
for(reverse @myelement){
  `sed -i '/ATOMIC_SPECIES/a $_  ${$myelement{$_}}[2]  $decoded->{$_}->{filename}' $currentPath/Optimize.in`
}
# #### deal with data ####
for my $id(0..$#filename){
  `mkdir -p $foldername/Optimize_$filename[$id]`; 
  open my $data ,"<$datafile[$id]" or die ("Can't open $filename[$id].data");
  my @data1 =<$data>;
  close $data;

  `cp $currentPath/Optimize.in $foldername/Optimize_$filename[$id]/Optimize_$filename[$id].in`;
# # ##############################atoms#######################
my @box;
my $boxx;
my $boxy;
my $boxz;
for (@data1){
  ###atoms###
        if(m/(\d+)\s+atoms/s){ 
          `sed -i 's:^nat.*:nat = $1:' $foldername/Optimize_$filename[$id]/Optimize_$filename[$id].in`;
        };
  ###type###
        if(m/(\d+)\s+atom\s+types/s){
          `sed -i 's:^ntyp.*:ntyp = $1:' $foldername/Optimize_$filename[$id]/Optimize_$filename[$id].in`;
        }
  ###ATOMIC_POSITION###
        if(m/^\d+\s+(\d+)\s+(\-?\d*.?\d*e*-*\d*)\s+(\-?\d*.?\d*e*-*\d*)\s+(\-?\d*.?\d*e*-*\d*)\s+-?\d+\s+-?\d+\s+-?\d+$/gm) #coord
        {
          my $i = $1-1;
          `sed -i '/ATOMIC_POSITIONS {angstrom}/a $myelement[$i] $2 $3 $4' $foldername/Optimize_$filename[$id]/Optimize_$filename[$id].in` ;    
        } 
  ###CELL_PARAMETERS###
  if(m/(\-?\d*\.*\d*\w*\+-?\d*)\sxlo/s){
          push @box,$1;
        }
        if(m/(\-?\d*\.*\d*\w*\+-?\d*)\sylo/s){
          push @box,$1;
        }
        if(m/(\-?\d*\.*\d*\w*\+-?\d*)\szlo/s){
          push @box,$1;
        }
        if(m/(\-?\d*\.*\d*\w*\+-?\d*)\s+(\-?\d*\.*\d*\w*\+-?\d*)\s+(\-?\d*\.*\d*\w*\+-?\d*)\s+xy\s+xz\s+yz/s){
          $boxx = "$box[0] $1 $2";
          $boxy = "$1 $box[1] $3";
          $boxz = "$2 $3 $box[2]";
        }
}
      `sed -i '/CELL_PARAMETERS {angstrom}/a $boxz' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
      `sed -i '/CELL_PARAMETERS {angstrom}/a $boxy' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
      `sed -i '/CELL_PARAMETERS {angstrom}/a $boxx' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
}

for my $filename(@filename){


  `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --job-name=Optimize_$filename' $slurmbatch`;
	
	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=Optimize_$filename.out' $slurmbatch`;
	
	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $QE_path -in Optimize_$filename.in' $slurmbatch`;
 #`sed -i '/mpiexec.* /opt/QEGCC/bin/pw.x/d' $slurmbatch`;
#	`sed -i '/#sed_anchor02/a mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Optimize$foldname.data.in' $slurmbatch`;
`cp $slurmbatch $foldername/Optimize_$filename/QE_slurmespresso_$filename.sh`;

  chdir("$foldername/Optimize_$filename/");
  #system("sbatch QE_slurmespresso_$filename.sh");
  chdir("$currentPath");
}
