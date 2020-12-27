#!/bin/bash
#SBATCH --ntasks=1                  # Number of MPI ranks
#SBATCH --cpus-per-task=1            # Number of OpenMP threads
#SBATCH -o heatseq-%j.out             # Standard output log
#SBATCH -e heatseq-%j.err             # Standard error  log     (optional)
#SBATCH --job-name=heatseq             # Job name
#SBATCH --time=00-01:00:00           # Time limit d-h:m:s
#SBATCH --partition=debug          # Partition to run the job
executable=heatseq
n_threads=1
	export OMP_NUM_THREADS=$n_threads
	srun ./$executable test-${1}.dat
        mv heat.ppm heatseq-${1}.ppm
