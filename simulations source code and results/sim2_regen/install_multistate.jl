#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-1:00:00
#SBATCH --ntasks=1
#SBATCH --mem=25g
#SBATCH --gres=lscratch:25
#=
module load julia
srun julia $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using Pkg
Pkg.add("CSV")
Pkg.add(url = "https://github.com/fintzij/MultistateModels.jl.git")