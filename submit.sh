#!/bin/bash -l
#SBATCH --job-name=pf2018
#SBATCH --output="pf2018.out"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --exclusive
#SBATCH --export=ALL
#SBATCH -t 200:00:00
# Choose a version of MATLAB by loading a module:
module load matlab/R2021a

# Remove -singleCompThread below if you are using parallel commands:
matlab -nodisplay -r "pfcompare"