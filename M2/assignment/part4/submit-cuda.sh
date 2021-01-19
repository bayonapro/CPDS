#!/bin/bash
#SBATCH --ntasks=1                  # Number of MPI ranks
#SBATCH --cpus-per-task=1            # Number of OpenMP threads
#SBATCH --tasks-per-node=1
#SBATCH --gres gpu:4
#SBATCH -o heatcuda-%j.out             # Standard output log
#SBATCH -e heatcuda-%j.err             # Standard error  log     (optional)
#SBATCH --job-name=heatcuda             # Job name
#SBATCH --time=00-01:00:00           # Time limit d-h:m:s
#SBATCH --partition=debug          # Partition to run the job
##SBATCH --exclude=nvb[2]

executable=./heatCUDA
txb=16

${executable} test.dat -t $txb
