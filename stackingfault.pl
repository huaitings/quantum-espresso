use strict;
use warnings;
use JSON::PP;
use Data::Dumper;
use POSIX;
use lib '.';
use HEA;
use  Cwd;
my $path = getcwd();
my @myelement = sort ("Al","Mo","Nb","Ta","Ti","Zr"); #!!!!
my $myelement = join ('',@myelement);
my $slurmbatch = "QE_slurmOpt.sh"; #slurm filename
my $QE_path = "/opt/QEGCC_MPICH3.4.2/bin/pw.x";
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

my $foldername = `find  $path/$myelement/Opt -type d -name "Opt-*"`;
my @foldername = split("\n", $foldername);
@foldername = sort @foldername;

for my $id (0..$#foldername)
{
    my @dataname = map (($_ =~ m/Opt-(\w+-\w+)/g),$foldername[$id]);
    #print "@dataname\n";
   # print "@foldername[1]\n";
      `cp $path/scf.in $path/$myelement/Opt/Opt-@dataname/stackingfault`;
    `rm -rf $path/$myelement/Opt/Opt-@dataname/stackingfault`;
    `mkdir -p $path/$myelement/Opt/Opt-@dataname/stackingfault`;
    if (-e "$path/$myelement/Opt/Opt-@dataname/Opt-@dataname.data")
    {     
        chdir("$path/$myelement/Opt/Opt-@dataname");
        system("atomsk Opt-@dataname.data -duplicate 1 1 6 Opt-@dataname-supercell.lmp");
        system("mv $path/$myelement/Opt/Opt-@dataname/Opt-@dataname-supercell.lmp $path/$myelement/Opt/Opt-@dataname/stackingfault");
        chdir("$path");
    }
    if (-e "$path/$myelement/Opt/Opt-@dataname/stackingfault/Opt-@dataname-supercell.lmp")
    {     
        chdir("$path/$myelement/Opt/Opt-@dataname/stackingfault");
        system("atomsk Opt-@dataname-supercell.lmp -select above 0.5*box Z -shift 1.0 0.0 0.0 Opt-@dataname-stackingfault.lmp");
        chdir("$path");
    }
}
chdir("$path");

my $datafile = `find $path/$myelement/Opt -maxdepth 3 -name "Opt-*-*-stackingfault.lmp"`;
my @datafile = split("\n", $datafile);
@datafile = sort @datafile;
#print "@datafile\n" ;
my @filename = map (($_ =~ m/.*\/Opt-(.*-.*)-stackingfault.lmp/gm),@datafile);
my @element = map(($_ =~ m/.*\/Opt-.*-(.*)-stackingfault.lmp/gm),@datafile);
#print  @element;
#print "@filename\n";

    for my $SFid(0..$#filename){
        my $folder = "$path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault";
          my @ele = split("([A-Z][a-z])",$element[$SFid]);
             @ele = map (($_ =~ m/([A-Z][a-z])/gm),@ele);
            my $elelegth = @ele;
            #print $elelegth;
            open my $data ,"<$datafile[$SFid]" or die ("Can't open $filename[$SFid]-stackingfault.lmp");
            my @data1 =<$data>;
            close $data;
           # print @data1;
             `cp $path/scf.in $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in`;
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
    `sed -i '/ATOMIC_SPECIES/a $_  ${$myelement{$_}}[2]  $decoded->{$_}->{filename}' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in`;
  }
    ##starting_magnetization###
  for (1..$#ele+1){
    `sed -i '/nspin = 2/a starting_magnetization($_) =  2.00000e-01' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in`;
  } 
### cutoff ###
    `sed -i 's:^ecutwfc.*:ecutwfc = $cutoff[-1]:' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in`;
    `sed -i 's:^ecutrho.*:ecutrho = $rho_cutoff[-1]:' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in`;  
  ###type###

    `sed -i 's:^ntyp.*:ntyp = $elelegth:' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in`;
for(@data1){
  ###atoms###
    if(m/(\d+)\s+atoms/s){ 
      $atoms = $1;
      `sed -i 's:^nat.*:nat = $1:' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in`;
    }
    if(m/\s+([+-]?\d+\.*\d+)\s+[+-]?\d+\.*\d+\s+xlo\s+xhi/s){
    $move = $1;
    }
    
}
for (@data1){
      ###### xlo #######
      ### 0.0 2.84708541500004 xlo xhi
      if(m/\s+([+-]?\d+\.*\d+)\s+([+-]?\d+\.*\d+)\s+xlo\s+xhi/s){
          $lx = $2-$1;
      }
      ###### ylo #######
      ### 0.0 2.847085238 ylo yhi
      if(m/\s+([+-]?\d+\.*\d+)\s+([+-]?\d+\.*\d+)\s+ylo\s+yhi/s){
          $ly = $2-$1;
      }
      ###### zlo #######
      ### 0.0 2.84708568799983 zlo zhi
      if(m/\s+([+-]?\d+\.*\d+)\s+([+-]?\d+\.*\d+)\s+zlo\s+zhi/s){
          $lz = $2-$1+10;
      }
      ###### xy xz yz #######
      ### -2.65999959883181e-07 9.26000039313875e-07 5.16000064963272e-07 xy xz yz
      if(m/(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\s+(\-?\d*\.*\d*\w*\+?-?\d*)\s+xy\s+xz\s+yz/s){
          $xy = $1;
          $xz = $2;
          $yz = $3;
      }

  ###ATOMIC_POSITION###
      if(m/\s+\d+\s+(\d+)\s+([+-]?\d+\.*\d+)\s+([+-]?\d+\.*\d+)\s+([+-]?\d+\.*\d+)/gm) #coord
      {
        my $i = $1-1;
        my $movex = $2 - $move;
        my $movey = $3 - $move;
        my $movez = $4 - $move; 
        `sed -i '/ATOMIC_POSITIONS {angstrom}/a @myelement[$i] $movex $movey $movez' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in` ;
  }
}
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $xz $yz $lz' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in` ;
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $xy $ly 0' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in` ;
    `sed -i '/CELL_PARAMETERS {angstrom}/a  $lx 0 0' $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].in` ;


    
#####################
  `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --job-name=scf-$filename[$SFid]' $slurmbatch`;
	
	`sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	`sed -i '/#sed_anchor01/a #SBATCH --output=scf-$filename[$SFid].sout' $slurmbatch`;
	
	`sed -i '/mpiexec.*/d' $slurmbatch`;
	`sed -i '/#sed_anchor02/a mpiexec $QE_path -in scf-$filename[$SFid].in' $slurmbatch`;

`cp $slurmbatch $path/$myelement/Opt/Opt-$filename[$SFid]/stackingfault/scf-$filename[$SFid].sh`;
  print qq($folder\n);
  chdir("$folder");
 # system("sbatch Opt-$filename[$id].sh");
  print qq(sbatch scf-$filename[$SFid].sh\n);
  chdir("$path");
  ####################
}
