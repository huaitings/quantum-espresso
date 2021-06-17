use strict;
use warnings;
use  Cwd;

my $currentPath = getcwd();
my @myelement = sort ("Co","Cr","Fe","Hf","Mn","Nb","Ni","Ta","Ti","Zr");
my $myelement = join ('',@myelement);

my $out_file = `find $currentPath/$myelement/Opt -name "*.sout"`;
my @out_file = split("\n", $out_file);
@out_file = sort @out_file; 
my @out_filename = map (($_ =~ m/(\w+-\w+-\w+).sout$/gm),@out_file);


my $folder = `find $currentPath/$myelement/Opt -type d -name "*-*-*"`;
my @folder = split("\n", $folder);
@folder = sort @folder;
my @foldername = map (($_ =~ m/(\w*\.?\w*[+-]*\w+-\w+-\w+)$/gm),@folder);


my $running = `squeue -o \%j | awk 'NR!=1'`;
my @running = split("\n",$running);
my %running;
for(@running){
    $running{$_} = 1;
}


print "DONE : \n";
for my $id1 (0..$#out_file){
      my $done = `grep -o -a 'DONE' $out_file[$id1]`; 
      chomp $done;
      if( $done eq "DONE" ){
        print "\t$out_filename[$id1]\n";
      }

}

print "QE calculating : \n";
for my $id2 (0..$#out_file){
    if( exists $running{$out_filename[$id2]}){
      print "\t$out_filename[$id2]\n";
    }
}

print "Not summited : \n";
for my $id3(0..$#folder){
    if (-e "$folder[$id3]/$foldername[$id3].sout" ){
        my $done = `grep -o -a 'DONE' $folder[$id3]/$foldername[$id3].sout`; 
        chomp $done;
        if( $done eq "DONE" ){
            next;
        }else{
          print "\t$foldername[$id3]\n";
          next;
        }
    }
    if( exists $running{$foldername[$id3]}){
      next;
    }
    print "\t$foldername[$id3]\n";
} 