#!/bin/sh
#sed_anchor01
#SBATCH --output=B1-TiZr.sout
#SBATCH --job-name=B1-TiZr
#SBATCH --nodes=1
#~ ##SBATCH --ntasks-per-node=12 
#SBATCH --partition=AMD24
#SBATCH --exclude=node17,node18

export LD_LIBRARY_PATH=/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
export PATH=/opt/mpich-3.3.2/bin:$PATH
#sed_anchor02
mpiexec /opt/lammps/lmp_mpi_bigwind -l none -in B1-TiZr.in

