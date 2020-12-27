#!/bin/bash
#SBATCH --ntasks=4                  # Number of MPI ranks
#SBATCH --cpus-per-task=1            # Number of OpenMP threads
#SBATCH --tasks-per-node=4
#SBATCH -o heatmpi-%j.out             # Standard output log
#SBATCH -e heatmpi-%j.err             # Standard error  log     (optional)
#SBATCH --job-name=heatmpi             # Job name
#SBATCH --time=00-01:00:00           # Time limit d-h:m:s
#SBATCH --partition=debug          # Partition to run the job

prog=heatmpi
procs=4

srun -n $procs ./$prog test-$1.dat
mv heat.ppm heatmpi-${1}.ppm
