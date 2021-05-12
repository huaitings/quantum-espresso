#use strict;
#use warnings;
use  Cwd;
my $path = getcwd();
my @myelement = sort ("Co","Cr","Fe","Mn","Ni"); #!!!!
my $myelement = join ('',@myelement);
my @slabsurface = ("100","110","111");
my $foldername = `find  ./$myelement/Opt -type d -name "Opt-*"`;
my @foldername = split("\n", $foldername);
@foldername = sort @foldername;
my $slurmbatch = "QE_slurmOpt.sh"; #slurm filename
my $QE_path = "/opt/opt/QEGCC_MPICH3.3.2/bin/pw.x";

for my $id (0..$#foldername){
    my @dataname = map (($_ =~ m/Opt-(\w+-\w+)/g),$foldername[$id]);
    `mkdir -p $path/$myelement/Opt/Opt-@dataname/Surface`;
    for my $surface (@slabsurface)
    {
    `mkdir -p $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface`;
    `cp $path/$myelement/Opt/Opt-@dataname/Opt-@dataname.in $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in`;
    chdir("$path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in");
    `sed -i '/&CONTROL/a nstep=100'  $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in`;
    `sed -i  's/calculation = "vc-relax"/calculation = "vc-md"/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in`;
    `sed -i  's/!tempw = 0/tempw = 100/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in`;
    `sed -i  's/ion_dynamics = "bfgs"/ion_dynamics = "beeman"/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in`;
    `sed -i  's/!ion_temperature = "rescaling"/ion_temperature = "rescaling"/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in`;
    `sed -i  's/cell_dynamics = "bfgs"/cell_dynamics = "pr"/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in`;
    ################### slab(100) ###################
           if($surface == "100"){
        chdir("$path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in");
           open my $surface100, "< $path/$myelement/Opt/Opt-@dataname/Surface/Surface100/Surface100-@dataname.in";
           my @surface100 = <$surface100>;
           close($surface100);
           for(@surface100)
           {
             if($_ =~ m/^(\d+\.\d+\w*[+-]*\d*)\s+(\d+\.\d+\w*[+-]*\d*)\s+(\d+\.\d+\w*[+-]*\d*)$/gm)
             {
                  push @slab100before,$1,$2,$3;
                  push @slab100after,$1,$2,$3*8;
             }
             `sed -i  's/@slab100before/@slab100after/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface100/Surface100-@dataname.in`;
             @slab100before = ();
             @slab100after = ();
           }
       }
    ################### slab(110) ###################
               if($surface == "110"){
        chdir("$path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in");
        open my $surface110, "< $path/$myelement/Opt/Opt-@dataname/Surface/Surface110/Surface110-@dataname.in";
        my @surface110 = <$surface110>;
        close($surface110);
        for(@surface110)
           {
             if($_ =~ m/^(\d+\.\d+\w*[+-]*\d*)\s+(\d+\.\d+\w*[+-]*\d*)\s+(\d+\.\d+\w*[+-]*\d*)$/gm)
             {
                push @slab110before,$1,$2,$3;
                push @slab110after,$1,$2*1.5,$3*7;
             }
             `sed -i  's/@slab110before/@slab110after/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface110/Surface110-@dataname.in`;
             @slab110before = ();
             @slab110after = ();
           }
       }
    ################### slab(111) ###################
               if($surface == "111"){
        chdir("$path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.in");
        open my $surface111, "< $path/$myelement/Opt/Opt-@dataname/Surface/Surface111/Surface111-@dataname.in";
        my @surface111 = <$surface111>;
        close($surface111);
        for(@surface111)
           {
             if($_ =~ m/^(\d+\.\d+\w*[+-]*\d*)\s+(\d+\.\d+\w*[+-]*\d*)\s+(\d+\.\d+\w*[+-]*\d*)$/gm)
             {
                push @slab111before,$1,$2,$3;
                push @slab111after,$1,$2,$3*5;
             }
             `sed -i  's/@slab111before/@slab111after/' $path/$myelement/Opt/Opt-@dataname/Surface/Surface111/Surface111-@dataname.in`;
             @slab111before = ();
             @slab111after = ();
           }
       }
        `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	    `sed -i '/#sed_anchor01/a #SBATCH --job-name=Surface$surface-@dataname' $slurmbatch`;
	
	    `sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	    `sed -i '/#sed_anchor01/a #SBATCH --output=Surface$surface-@dataname.out' $slurmbatch`;
	
        `sed -i '/mpiexec.*/d' $slurmbatch`;
        `sed -i '/#sed_anchor02/a $QE_path -in Surface$surface-@dataname.in' $slurmbatch`;

        `cp $slurmbatch $path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/Surface$surface-@dataname.sh`;
        chdir("$path/$myelement/Opt/Opt-@dataname/Surface/Surface$surface/");
        #system("sbatch Surface$surface-@dataname.sh");
        chdir("$path");
    }#slab how many surfaces
}#Opt folder 
