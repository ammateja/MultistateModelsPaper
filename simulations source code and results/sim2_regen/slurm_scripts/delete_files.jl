#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-04:00:00
#SBATCH --ntasks=1
#SBATCH --mem=50g
#SBATCH --gres=lscratch:5
#=
module load julia
srun julia $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

rm("/data/fintzijr/multistate/.sim2_regen_delete", recursive = true, force = true)
