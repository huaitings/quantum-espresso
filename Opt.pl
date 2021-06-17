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

my $cleanall = "yes";

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

my @rho_cutoff;
my @cutoff;
for (@myelement){
 push @rho_cutoff,$decoded->{$_}->{rho_cutoff};
 push @cutoff,$decoded->{$_}->{cutoff};
}
my @rho_cutoff_sort = sort {$a<=>$b} @rho_cutoff;
my @cutoff_sort = sort {$a<=>$b} @cutoff;
#########################################HEA.pm#######################################
my %myelement;
for (@myelement){
    chomp;
     @{$myelement{$_}} = &HEA::eleObj("$_"); 
}
################################################
my $datafile = `find $currentPath/$myelement/data -name "out-*-*.data"`;
my @datafile = split("\n",$datafile);
@datafile = sort @datafile;
my @filename = map (($_ =~ m/(\w+.\w+).data$/gm),@datafile);
my @structure = map (($_ =~ m/^(\w+).\w+$/gm),@filename);

my $out_file = `find $currentPath/$myelement/Opt -name "Opt-*.sout"`;
my @out_file = split("\n", $out_file);
@out_file = sort @out_file;
my @out_filename = map (($_ =~ m/(Opt-\w+-\w+).sout$/gm),@out_file);



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
 ###ATOMIC_SPECIES###
for(reverse @myelement){
  `sed -i '/ATOMIC_SPECIES/a $_  ${$myelement{$_}}[2]  $decoded->{$_}->{filename}' $currentPath/Opt.in`

}
 ###starting_magnetization###

for (1..$#myelement+1){
  `sed -i '/nspin = 2/a starting_magnetization($_) =  2.00000e-01' $currentPath/Opt.in`
} 


# # #### deal with data ####
for my $id(0..$#filename){


  if($cleanall eq "no"){
    if( exists $running{$out_filename[$id]}){
      next;
    }
    if (-e "$currentPath/$myelement/Opt/Opt-$filename[$id]/Opt-$filename[$id].sout" ){
      my $done = `grep -o -a 'DONE' $currentPath/$myelement/Opt/Opt-$filename[$id]/Opt-$filename[$id].sout`; 
      chomp $done;

      if( $done eq "DONE" ){
        next;
      }
    }
  }

  `mkdir -p $foldername/Opt-$filename[$id]`; 
  open my $data ,"<$datafile[$id]" or die ("Can't open $filename[$id].data");
  my @data1 =<$data>;
  close $data;

  `cp $currentPath/Opt.in $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
# # ##############################atoms#######################
my $atoms;
my $move;
 my $a;
# my $c;
my @box;
my $boxx;
my $boxy;
my $boxz;
for(@data1){
  ###atoms###
    if(m/(\d+)\s+atoms/s){ 
      $atoms = $1;
      `sed -i 's:^nat.*:nat = $1:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    }
  ###type###
    if(m/(\d+)\s+atom\s+types/s){
      `sed -i 's:^ntyp.*:ntyp = $1:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    }
  ###cutoff###
      `sed -i 's:^ecutwfc.*:ecutwfc = $cutoff_sort[-1]:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
      `sed -i 's:^ecutrho.*:ecutrho = $rho_cutoff_sort[-1]:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;    
  ###CELL_PARAMETERS###
  if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s\-?\d*\.*\d*\w*\+?-?\d*\sxlo/s){
      $move = $1;
  }
}
for (@data1){
  if($move == 0){
  #     if(m/\-?\d*\.*\d*\w*\+?-?\d*\s(\-?\d*\.*\d*\w*\+?-?\d*)\sxlo/s) #coord
  #     {  
  #       $a = $1;
  #     }
  #     if(m/\-?\d*\.*\d*\w*\+?-?\d*\s(\-?\d*\.*\d*\w*\+?-?\d*)\szlo/s) #coord
  #         {  
  #       $c = $1;
  #     }
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
  }elsif(m/$atoms\s+\d+\s+(\-?\d*.?\d*e*[+-]*\d*)\s+\-?\d*.?\d*e*[+-]*\d*\s+(\-?\d*.?\d*e*[+-]*\d*)\s-?\d+\s-?\d+\s-?\d+/s) #coord
  {  
       $a = ($1 - $move)*2;
  #     $c = ($1 - $move)*2;
      $boxx = "$a 0.00 0.00";
      $boxy = "0.00 $a 0.00";
      $boxz = "0.00 0.00 $a";
  }

  ###ATOMIC_POSITION###
        if(m/^\d+\s+(\d+)\s+(\-?\d*.?\d*e*[+-]*\d*)\s+(\-?\d*.?\d*e*[+-]*\d*)\s+(\-?\d*.?\d*e*[+-]*\d*)\s-?\d+\s-?\d+\s-?\d+$/gm) #coord
        {
          my $i = $1-1;
          my $movex = $2 - $move;
          my $movey = $3 - $move;
          my $movez = $4 - $move; 
          `sed -i '/ATOMIC_POSITIONS {angstrom}/a $myelement[$i] $movex $movey $movez' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;    
        } 
}
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $boxz' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $boxy' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $boxx' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in` ;

  ###ibrav###
    # if($structure[$id] eq "fcc" || $structure[$id] eq "B1" ){
    #     `sed -i 's:^ibrav.*:ibrav = 2:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    #     `sed -i '/ibrav = 2/a celldm(1) = $cell1' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    # }
    # if($structure[$id] eq "bcc" ){
    #     `sed -i 's:^ibrav.*:ibrav = 3:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    #     `sed -i '/ibrav = 3/a celldm(1) = $cell1' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;  
    # }
    # if($structure[$id] eq "hcp"  ){
    #     `sed -i 's:^ibrav.*:ibrav = 4:' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    #     `sed -i '/ibrav = 4/a celldm(1) = $cell1' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    #     `sed -i '/ibrav = 4/a celldm(3) = $cell3' $foldername/Opt-$filename[$id]/Opt-$filename[$id].in`;
    # }



  `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --job-name=Opt-$filename[$id]' $slurmbatch`;
	
	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=Opt-$filename[$id].sout' $slurmbatch`;
	
	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $QE_path -in Opt-$filename[$id].in' $slurmbatch`;
 #`sed -i '/mpiexec.* /opt/QEGCC/bin/pw.x/d' $slurmbatch`;
#	`sed -i '/#sed_anchor02/a mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Optimize$foldname.data.in' $slurmbatch`;
`cp $slurmbatch $foldername/Opt-$filename[$id]/Opt-$filename[$id].sh`;
  chdir("$foldername/Opt-$filename[$id]/");
  print 	qq($foldername/Opt-$filename[$id]/\n);
  system("sbatch Opt-$filename[$id].sh");
  print qq(sbatch Opt-$filename[$id].sh\n);

  chdir("$currentPath");

}
