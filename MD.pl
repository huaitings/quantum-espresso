use strict;
use warnings;
use  Cwd;
my $path = getcwd();
my @myelement = sort ("Co","Cr","Fe","Hf","Mn","Nb","Ni","Ta","Ti","Zr");
my $myelement = join ('',@myelement);
my $slurmbatch = "QE_slurmOpt.sh"; #slurm filename

my $QE_path = "/opt/QEGCC/bin/pw.x";
my @pressure = ("-0","+500","-500");  #!!!!!! pressure !!!!!!
my @temperature = ("0.1","200"); #!!!!!! temperature !!!!!!

my $foldername = `find  $path/$myelement/Opt -type d -name "Opt-*"`;
my @foldername = split("\n", $foldername);
@foldername = sort @foldername;


for my $id (0..$#foldername){

    my @dataname = map (($_ =~ m/Opt-(\w+-\w+)/g),$foldername[$id]);
    `rm -rf $path/$myelement/Opt/Opt-@dataname/MD`;

    foreach my $temp (@temperature)
    {
        foreach my $press (@pressure)
        { 
        system("mkdir -p $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname");

        `cp $path/$myelement/Opt/Opt-@dataname/Opt-@dataname.in $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.in`;

        system("sed -i 's/!press = 0/press = $press/' $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.in");
        system("sed -i 's/vc-relax/vc-md/'  $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.in");
        system("sed -i 's/!ion_temperature/ion_temperature/'  $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.in");
        system("sed -i 's/ion_dynamics = \"bfgs\"/ion_dynamics = \"beeman\"/'  $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.in");                 
        system("sed -i 's/!tempw = 0/tempw = 300/'  $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.in"); 
        system("sed -i 's/cell_dynamics = \"bfgs\"/cell_dynamics = \"pr\"/'  $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.in"); 




        `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	    `sed -i '/#sed_anchor01/a #SBATCH --job-name=$temp\\K$press\\Gpa-@dataname' $slurmbatch`;
	
	    `sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	    `sed -i '/#sed_anchor01/a #SBATCH --output=$temp\\K$press\\Gpa-@dataname.sout' $slurmbatch`;
	
        `sed -i '/mpiexec.*/d' $slurmbatch`;
        `sed -i '/#sed_anchor02/a mpiexec $QE_path -in $temp\\K$press\\Gpa-@dataname.in' $slurmbatch`;
         #`sed -i '/mpiexec.* /opt/QEGCC/bin/pw.x/d' $slurmbatch`;
         #`sed -i '/#sed_anchor02/a mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Optimize$foldname.data.in' $slurmbatch`;
        `cp $slurmbatch $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/$temp\\K$press\\Gpa-@dataname.sh`;
        chdir("$path/$myelement/Opt/Opt-@dataname/MD/$temp\\K$press\\Gpa-@dataname/");
        # system("sbatch 300K-$press\\Gpa-@dataname.sh");
        chdir("$path");

         }

 
        # system("mkdir -p $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname"); #make MD folder

        # `cp $path/$myelement/Opt/Opt-@dataname/Opt-@dataname.in $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.in`;

        # system("sed -i 's/!press = 0/press = 0/' $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.in");
        # system("sed -i 's/vc-relax/vc-md/' $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.in");
        # system("sed -i 's/!ion_temperature/ion_temperature/' $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.in");
        # system("sed -i 's/ion_dynamics = \"bfgs\"/ion_dynamics = \"beeman\"/' $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.in");                    
        # system("sed -i 's/!tempw = 0/tempw = $temp/'  $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.in");  
        # system("sed -i 's/cell_dynamics = \"bfgs\"/cell_dynamics = \"pr\"/'  $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.in"); 


        # `sed -i '/#SBATCH.*--job-name/d' $slurmbatch`;
	    # `sed -i '/#sed_anchor01/a #SBATCH --job-name=$temp\\K-00Gpa-@dataname' $slurmbatch`;
	
	    # `sed -i '/#SBATCH.*--output/d' $slurmbatch`;
	    # `sed -i '/#sed_anchor01/a #SBATCH --output=300K-$temp\\K-00Gpa-@dataname.sout' $slurmbatch`;
	
        # `sed -i '/mpiexec.*/d' $slurmbatch`;
        # `sed -i '/#sed_anchor02/a mpiexec $QE_path -in $temp\\K-00Gpa-@dataname.in' $slurmbatch`;
        #  #`sed -i '/mpiexec.* /opt/QEGCC/bin/pw.x/d' $slurmbatch`;
        #  #`sed -i '/#sed_anchor02/a mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Optimize$foldname.data.in' $slurmbatch`;
        # `cp $slurmbatch $path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/$temp\\K-00Gpa-@dataname.sh`;
        # chdir("$path/$myelement/Opt/Opt-@dataname/MD/$temp\\K-00Gpa-@dataname/");
        # # system("sbatch $temp\\K-00Gpa-@dataname.sh");
        # chdir("$path");


    }
}


