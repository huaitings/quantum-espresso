use strict;
use warnings;
use  Cwd;

my $currentPath = getcwd();
my @myelement = sort ("Co","Cr","Fe","Hf","Mn","Nb","Ni","Ta","Ti","Zr");
my $myelement = join ('',@myelement);

my $out_file = `find $currentPath/$myelement/Opt -name "*.sout"`;
my @out_file = split("\n", $out_file);
@out_file = sort @out_file; 
my @out_filename = map (($_ =~ m/.*\/(.*).sout$/gm),@out_file);


my $folder = `find $currentPath/$myelement/Opt -type d -name "*-*-*"`;
my @folder = split("\n", $folder);
@folder = sort @folder;
my @foldername = map (($_ =~ m/.*\/(.*)$/gm),@folder);


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
for my $id2 (0..$#foldername){
    if( exists $running{$foldername[$id2]}){
      print "\t$foldername[$id2]\n";
    }
}

print "Not summited : \n";
for my $id3(0..$#folder){
  if( exists $running{$foldername[$id3]}){
    next;
  }
  if (-e "$folder[$id3]/$foldername[$id3].sout" ){
        my $done = `grep -o -a 'DONE' $folder[$id3]/$foldername[$id3].sout`; 
        chomp $done;
        if( $done eq "DONE" ){
            next;
        }
  }

    print "\t$foldername[$id3]\n";
} 