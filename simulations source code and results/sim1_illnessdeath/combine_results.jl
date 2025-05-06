#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-02:45:00
#SBATCH --ntasks=1
#SBATCH --mem=25g
#SBATCH --gres=lscratch:5
#=
module load julia
srun julia $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using BSON
using CSV
using DataFrames

# files = [joinpath("sim1_illnessdeath", "results", "illnessdeath_results_$k.bson") for k in 1:12000]
files = ["illnessdeath_results_$k.bson" for k in 1:12000]
res = mapreduce(x -> BSON.load(x)[:results], vcat, files)

# write csv
# CSV.write(joinpath("sim1_illnessdeath", "results", "illnessdeath_results.csv"), res)
# CSV.write("illnessdeath_results_full.csv", res)
CSV.write("illnessdeath_results_exact.csv", res)