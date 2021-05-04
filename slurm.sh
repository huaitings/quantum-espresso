#!/bin/sh
#sed_anchor01
#SBATCH --output=Zr.sout
#SBATCH --job-name=Zr
#SBATCH --nodes=1
#~ ##SBATCH --ntasks-per-node=12 
#SBATCH --partition=INTEL

export LD_LIBRARY_PATH=/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
export PATH=/opt/QEGCC_MPICH3.3.2/bin:$PATH
#sed_anchor02
/opt/lammps/lmp_mpi_bigwind -l none -in Zr.in
/opt/lammps/lmp_mpi_bigwind -l none -in Ti.in
/opt/lammps/lmp_mpi_bigwind -l none -in Ta.in
/opt/lammps/lmp_mpi_bigwind -l none -in Nb.in
/opt/lammps/lmp_mpi_bigwind -l none -in Mo.in
/opt/lammps/lmp_mpi_bigwind -l none -in Al.in
/opt/lammps/lmp_mpi_bigwind -l none -in Zr.in
/opt/lammps/lmp_mpi_bigwind -l none -in Ti.in
/opt/lammps/lmp_mpi_bigwind -l none -in Ta.in
/opt/lammps/lmp_mpi_bigwind -l none -in Nb.in
/opt/lammps/lmp_mpi_bigwind -l none -in Mo.in
/opt/lammps/lmp_mpi_bigwind -l none -in Al.in


##SBATCH --nodelist=node01