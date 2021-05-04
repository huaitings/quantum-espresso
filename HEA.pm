##This module is developed by Prof. Shin-Pon JU at NSYSU on March 28 2021
package HEA; 

use strict;
use warnings;

our (%element); # density (g/cm3), arrangement, mass, lat a , lat c

$element{"Al"} = [2.7,"fcc",26.981539,4.046,4.046]; 
$element{"Mo"} = [10.28,"fcc",95.95,3.142,3.142]; 
$element{"Nb"} = [8.57,"bcc",92.90638,3.30,3.30]; 
$element{"Ta"} = [16.69,"bcc",180.94788,3.30,3.30]; 
$element{"Ti"} = [4.506,"hcp",47.867,2.95,4.685]; 
$element{"Zr"} = [6.52,"hcp",91.224,3.232,5.147]; 
$element{"Co"} = [8.9,"hcp",58.933,2.5071,4.0695]; 
$element{"Cr"} = [7.19,"bcc",51.9961,2.91,2.91]; 
$element{"Fe"} = [7.874,"bcc",55.845,2.8665,2.8665]; 
$element{"Mn"} = [7.21,"bcc",54.938,3.750,3.750]; 
$element{"Hf"} = [13.31,"hcp",178.49,3.1964,5.0511]; 
$element{"Ni"} = [8.908,"fcc",58.693,3.524,3.524]; 
our (%fitted); #rc, attrac, repuls, Cmin, Cmax
$fitted{"Al"} = [3.9,0.05,0.05,0.49,2.80]; 
$fitted{"Mo"} = [3.96,0,0,0.82,2.50]; 
$fitted{"Nb"} = [3.95,0,0,0.36,2.80]; 
$fitted{"Ta"} = [3.96,0,0,0.25,2.80]; 
$fitted{"Ti"} = [4.4,0,0,1.00,1.44]; 
$fitted{"Zr"} = [4.84,0,0,1.00,1.44]; 
$fitted{"Co"} = [3.8,0,0,0.49,2.00]; 
$fitted{"Cr"} = [3.55,0.02,0.10,0.71,2.80]; 
$fitted{"Fe"} = [3.45,0.05,0.05,0.36,2.80]; 
$fitted{"Mn"} = [10.8,0,0,0.16,2.80]; 
$fitted{"Hf"} = [4.75,-0.02,-0.08,0.66,2.28]; 
$fitted{"Ni"} = [3.95,0.05,0.05,0.81,2.80]; 

#Ms rc 
#$fitted{"Nb"} = 3.99
#$fitted{"Ta"} = 3.99
#$fitted{"Ti"} = 3.54 4.4
#$fitted{"Zr"} = 3.88 4.84
#$fitted{"Co"} = 3.02 or 3.8
#$fitted{"Cr"} = 3.48
#$fitted{"Fe"} = 3.46
#$fitted{"Mn"} = [10.8,0,0,0.16,2.80]; 
#$fitted{"Hf"} = 3.83 4.76
#$fitted{"Ni"} = 3.92


sub eleFit {
    my $elef = shift @_;
   return (@{$fitted{"$elef"}});
}
sub eleObj {# return properties of an element
   my $elem = shift @_;
   return (@{$element{"$elem"}});
}

1;               # Loaded successfully
