#!/bin/sh
#sed_anchor01
#SBATCH --output=Optimize_hcp-Zr.out
#SBATCH --job-name=Optimize_hcp-Zr
#SBATCH --nodes=1
#~ ##SBATCH --ntasks-per-node=12 
#SBATCH --partition=INTEL

export LD_LIBRARY_PATH=/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
export PATH=/opt/QEGCC_MPICH3.3.2/bin:$PATH
#sed_anchor02
mpiexec /opt/QEGCC_MPICH3.3.2/bin/pw.x -in Optimize_hcp-Zr.in



