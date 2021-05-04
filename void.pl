use strict;
use warnings;
use  Cwd;
my $path = getcwd();
my @myelement = sort ("Co","Cr","Fe","Hf","Mn","Nb","Ni","Ta","Ti","Zr");
my $myelement = join ('',@myelement);
my $slurmbatch = "QE_slurmVoid.sh"; #slurm filename

my $QE_path = "/opt/QEGCC/bin/pw.x";

my $foldername = `find  ./$myelement/Opt -type d -name "Opt-*"`;
my @foldername = split("\n", $foldername);
@foldername = sort @foldername;

for my $id (0..$#foldername){
    my @dataname = map (($_ =~ m/Opt-(\w+-\w+)/g),$foldername[$id]);
    `mkdir -p $path/$myelement/Opt/Opt-@dataname/Void`;
    `cp $path/$myelement/Opt/Opt-@dataname/Opt-@dataname.in $path/$myelement/Opt/Opt-@dataname/Void/Void-@dataname.in`;
    open my $all, "< $path/$myelement/Opt/Opt-@dataname/Void/Void-@dataname.in";
    my @all = <$all>;
    close($all);

    for(@all){
        if (m/nat\s+\=\s+(\d+)/g){
            my $atom = $1 ;
            my $voidatom = $atom-1;

            `sed -i  's/nat = $atom/nat = $voidatom/' $path/$myelement/Opt/Opt-@dataname/Void/Void-@dataname.in`;
        }

    }
    `sed -i -e '/ATOMIC_POSITIONS {angstrom}/{n;d}' $path/$myelement/Opt/Opt-@dataname/Void/Void-@dataname.in`;
}


#     chdir ("$path/$optimize_file/");
#     system("mkdir -p void/void$optimize_file/");
#     system("cp $optimize_file.in void/void$optimize_file/");
#     chdir ("$path/$optimize_file/void/void$optimize_file/");
#     my @atom = grep {if( m/nat\s+\=\s+(\d+)/g){$_ = $1;}} @all;
#     #print $atom[$_];
    
# $voidatom = $atom[$_] - 1;
# print  $voidatom ;
#    `sed -i  's/nat = $atom[$_]/nat = $voidatom/' $optimize_file.in`;
   #`sed  's/nat = @atom[$_]/nat = @voidatom[$_]/' $optimize_file.in`;
    #`sed 's/^nat/@atom[$_]/' `;     
#`sed -i -e '/ATOMIC_POSITIONS {angstrom}/{n;d}' $optimize_file.in`;
#print @atom[$_];


