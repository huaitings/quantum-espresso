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

my $cleanall = "no";

my $myelement = join('',@myelement);
########################################json##########################################
my $json;
{
    local $/ = undef;
    open my $fh, '<', '/opt/QEpot/SSSP_efficiency.json';
    $json = <$fh>;
    close $fh;
}
my $decoded = decode_json($json);

######   cutoff   #######
my @rho_cutoff;
my @cutoff;
for (@myelement){
 push @rho_cutoff,$decoded->{$_}->{rho_cutoff};
 push @cutoff,$decoded->{$_}->{cutoff};
}
 @rho_cutoff = sort {$a<=>$b} @rho_cutoff;
 @cutoff = sort {$a<=>$b} @cutoff;

#########################     HEA.pm       #####################
my %myelement;
for (@myelement){
    chomp;
     @{$myelement{$_}} = &HEA::eleObj("$_"); 
}
################################################
my $datafile = `find $currentPath/$myelement/data -name "out-*-*.data"`;
my @datafile = split("\n",$datafile);
@datafile = sort @datafile;
my @filename = map (($_ =~ m/out-(.*).data$/gm),@datafile);
my @element = map (($_ =~ m/^\w+-(\w+)$/gm),@filename);
my @structure = map (($_ =~ m/^(\w+)-\w+$/gm),@filename);


my $out_file = `find $currentPath/$myelement/Opt -maxdepth 2 -name "Opt-*.sout"`;
my @out_file = split("\n", $out_file);
@out_file = sort @out_file;
my @out_filename = map (($_ =~ m/.*\/(.*).sout$/gm),@out_file);
my @out_path = map (($_ =~ m/(.*)\/.*.sout$/gm),@out_file);


my $running = `squeue -o \%j | awk 'NR!=1'`;
my @running = split("\n",$running);
my %running;
for(@running){
    $running{$_} = 1;
}



`sed -i '/ATOMIC_SPECIES/,/ATOMIC_POSITIONS {angstrom}/{/ATOMIC_SPECIES/!{/ATOMIC_POSITIONS {angstrom}/!d}}' $currentPath/Opt.in`;
`sed -i '/ATOMIC_POSITIONS {angstrom/,/CELL_PARAMETERS {angstrom}/{/ATOMIC_POSITIONS {angstrom}/!{/CELL_PARAMETERS {angstrom}/!d}}' $currentPath/Opt.in`;
`sed -i '/CELL_PARAMETERS {angstrom}/,/!End/{/CELL_PARAMETERS {angstrom}/!{/!End/!d}}' $currentPath/Opt.in`;
`sed -i '/nspin = 2/,/!systemend/{/nspin = 2/!{/!systemend/!d}}' $currentPath/Opt.in`;



# #### deal with data ####
for my $id(0..$#filename){
  my $foldername = "$currentPath/$myelement/Opt/Opt-$filename[$id]";
  my @ele = split("([A-Z][a-z])",$element[$id]);
  @ele = map (($_ =~ m/([A-Z][a-z])/gm),@ele);
  my $elelegth = @ele;
  if($cleanall eq "no"){
    if( exists $running{"Opt-$filename[$id]"}){
      next;
    }
    if (-e "$foldername/Opt-$filename[$id].sout" ){
      my $done = `grep -o -a 'DONE' $foldername/Opt-$filename[$id].sout`; 
      chomp $done;

      if( $done eq "DONE" ){
        next;
      }
    }
  }

  `mkdir -p $foldername`; 

  open my $data ,"<$datafile[$id]" or die ("Can't open $filename[$id].data");
  my @data1 =<$data>;
  close $data;

  `cp $currentPath/Opt.in $foldername/Opt-$filename[$id].in`;
# # ##############################atoms#######################
my $atoms;
my $move;
my $lx;
my $ly;
my $lz; 
my $xy = 0;
my $xz = 0;
my $yz = 0;


  ###ATOMIC_SPECIES###
  for(reverse @ele){
    `sed -i '/ATOMIC_SPECIES/a $_  ${$myelement{$_}}[2]  $decoded->{$_}->{filename}' $foldername/Opt-$filename[$id].in`;
  }
  ##starting_magnetization###
  for (1..$#ele+1){
    `sed -i '/nspin = 2/a starting_magnetization($_) =  2.00000e-01' $foldername/Opt-$filename[$id].in`;
  } 
  ### cutoff ###
      `sed -i 's:^ecutwfc.*:ecutwfc = $cutoff[-1]:' $foldername/Opt-$filename[$id].in`;
      `sed -i 's:^ecutrho.*:ecutrho = $rho_cutoff[-1]:' $foldername/Opt-$filename[$id].in`;    
  ###type###

      `sed -i 's:^ntyp.*:ntyp = $elelegth:' $foldername/Opt-$filename[$id].in`;
for(@data1){
  ###atoms###
    if(m/(\d+)\s+atoms/s){ 
      $atoms = $1;
      `sed -i 's:^nat.*:nat = $1:' $foldername/Opt-$filename[$id].in`;
    }
  # ###type###
  #   if(m/(\d+)\s+atom\s+types/s){
  #     `sed -i 's:^ntyp.*:ntyp = $1:' $foldername/Opt-$filename[$id].in`;
  #   }
  ###CELL_PARAMETERS###
  if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s\-?\d*\.*\d*\w*\+?-?\d*\sxlo/s){
      $move = $1;
  }
}
for (@data1){
      ###### xlo #######
      ### 0.0 2.84708541500004 xlo xhi
      if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\sxlo/s){
          $lx = $2-$1;
      }
      ###### ylo #######
      ### 0.0 2.847085238 ylo yhi
      if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\sylo/s){
          $ly = $2-$1;
      }
      ###### zlo #######
      ### 0.0 2.84708568799983 zlo zhi
      if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\szlo/s){
          $lz = $2-$1;
      }
      ###### xy xz yz #######
      ### -2.65999959883181e-07 9.26000039313875e-07 5.16000064963272e-07 xy xz yz
      if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\s+xy\s+xz\s+yz/s){
          $xy = $1;
          $xz = $2;
          $yz = $3;
      }

  ###ATOMIC_POSITION###
      if(m/^\d+\s+(\d+)\s+(\-?\d*.?\d*e*[+-]*\d*)\s+(\-?\d*.?\d*e*[+-]*\d*)\s+(\-?\d*.?\d*e*[+-]*\d*)\s-?\d+\s-?\d+\s-?\d+$/gm) #coord
      {
        my $i = $1-1;
        my $movex = $2 - $move;
        my $movey = $3 - $move;
        my $movez = $4 - $move; 
        `sed -i '/ATOMIC_POSITIONS {angstrom}/a $myelement[$i] $movex $movey $movez' $foldername/Opt-$filename[$id].in` ;
  }
}
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $xz $yz $lz' $foldername/Opt-$filename[$id].in` ;
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $xy $ly 0' $foldername/Opt-$filename[$id].in` ;
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $lx 0 0' $foldername/Opt-$filename[$id].in` ;




  `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --job-name=Opt-$filename[$id]' $slurmbatch`;
	
	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=Opt-$filename[$id].sout' $slurmbatch`;
	
	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $QE_path -in Opt-$filename[$id].in' $slurmbatch`;
 #`sed -i '/mpiexec.* /opt/QEGCC/bin/pw.x/d' $slurmbatch`;
#	`sed -i '/#sed_anchor02/a mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Optimize$foldname.data.in' $slurmbatch`;
`cp $slurmbatch $foldername/Opt-$filename[$id].sh`;
  print 	qq($foldername\n);
  chdir("$foldername");
  # system("sbatch Opt-$filename[$id].sh");
  print qq(sbatch Opt-$filename[$id].sh\n);
  chdir("$currentPath");

}
