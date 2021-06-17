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
my $QE_path = "/opt/QEGCC_MPICH3.3.2/bin/pw.x";
my @myelement = sort ("Co","Cr","Fe","Hf","Mn","Nb","Ni","Ta","Ti","Zr");
my $myelement = join('',@myelement);
my $foldername = "$currentPath/$myelement/Opt";
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
my $datafile = `find $currentPath/$myelement -name "*-*-*.data"`;
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
  `mkdir -p $foldername/Opt-$filename[$id]`; 
  open my $data ,"<$datafile[$id]" or die ("Can't open $filename[$id].data");
  my @data1 =<$data>;
  close $data;

  `cp $currentPath/Optimize.in $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
# # ##############################atoms#######################
my @box;
my $boxx;
my $boxy;
my $boxz;
for (@data1){
  ###atoms###
        if(m/(\d+)\s+atoms/s){ 
          `sed -i 's:^nat.*:nat = $1:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
        };
  ###type###
        if(m/(\d+)\s+atom\s+types/s){
          `sed -i 's:^ntyp.*:ntyp = $1:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
        }
  ###ATOMIC_POSITION###
        if(m/^\d+\s+(\d+)\s+(\-?\d*.?\d*e*[+-]*\d*)\s+(\-?\d*.?\d*e*[+-]*\d*)\s+(\-?\d*.?\d*e*[+-]*\d*)\s-?\d+\s-?\d+\s-?\d+$/gm) #coord
        {
          my $i = $1-1;
          `sed -i '/ATOMIC_POSITIONS {angstrom}/a $myelement[$i] $2 $3 $4' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;    
        } 
  ###CELL_PARAMETERS###
        if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\sxlo/s){
          push @box,$1;
          $boxx = "$box[0] 0.00 0.00";
        }
        if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\sylo/s){
          push @box,$1;
          $boxy = "0.00 $box[1] 0.00";
        }
        if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\szlo/s){
          push @box,$1;
          $boxz = "0.00 0.00 $box[2]";
        }
        if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\s+xy\s+xz\s+yz/s){
          $boxx = "$box[0] $1 $2 ";
          $boxy = "$1 $box[1] $3 ";
          $boxz = "$2 $3 $box[2] ";

        }
}
      `sed -i '/CELL_PARAMETERS {angstrom}/a  $boxz' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
      `sed -i '/CELL_PARAMETERS {angstrom}/a  $boxy' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
      `sed -i '/CELL_PARAMETERS {angstrom}/a  $boxx' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
}


for my $filename(@filename){


  `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --job-name=Opt-$filename' $slurmbatch`;
	
	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=Opt-$filename.sout' $slurmbatch`;
	
	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $QE_path -in Opt-$filename.in' $slurmbatch`;
 #`sed -i '/mpiexec.* /opt/QEGCC/bin/pw.x/d' $slurmbatch`;
#	`sed -i '/#sed_anchor02/a mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Optimize$foldname.data.in' $slurmbatch`;
`cp $slurmbatch $foldername/Opt-$filename/QE_slurmOpt-$filename.sh`;
  chdir("$foldername/Opt-$filename/");
  print 	qq($foldername/Opt-$filename/\n);
  system("sbatch QE_slurmOpt-$filename.sh");
  sleep (2);
  print qq(sbatch QE_slurmOpt-$filename.sh\n);
  chdir("$currentPath");
}