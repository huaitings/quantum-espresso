#!/bin/sh
#sed_anchor01
#SBATCH --output=Opt-hcp-Zr.sout
#SBATCH --job-name=Opt-hcp-Zr
#SBATCH --nodes=1
#~ ##SBATCH --ntasks-per-node=12 
#SBATCH --partition=AMD24
#SBATCH --exclude=node18

export LD_LIBRARY_PATH=/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
export PATH=/opt/mpich-3.3.2/bin:$PATH
#sed_anchor02
mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Opt-hcp-Zr.in




