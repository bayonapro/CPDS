#!/bin/bash
#SBATCH --ntasks=1                  # Number of MPI ranks
#SBATCH --cpus-per-task=12            # Number of OpenMP threads
#SBATCH -o heatomp-%j.out             # Standard output log
#SBATCH -e heatomp-%j.err             # Standard error  log     (optional)
#SBATCH --job-name=heatomp             # Job name
#SBATCH --time=00-01:00:00           # Time limit d-h:m:s
#SBATCH --partition=debug          # Partition to run the job

executable=heatomp
n_threads=2
# MAX_THREADS=12
MAX_THREADS=16
while (test $n_threads -le $MAX_THREADS)
  do
	export OMP_NUM_THREADS=$n_threads
	srun ./$executable test-$1.dat
        mv heat.ppm heatomp-${1}.ppm
        n_threads=`expr $n_threads + 2`
  done
