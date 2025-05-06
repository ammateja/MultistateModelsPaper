#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
# SBATCH --constraint="e7543"
#SBATCH --mem=10g
#SBATCH --gres=lscratch:5
#=
module load julia
export JULIA_NUM_THREADS=64
srun julia --threads 64 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

# packages
using ArraysOfArrays
using Chain
using CSV
using DataFrames
using DataFramesMeta
using Distributions
using LinearAlgebra
using MultistateModels
using StatsBase
using Random
using RCall

include("sim_funs.jl")
# include("Code/simulations/sim2_regen/sim_funs.jl")

# preallocate
testdat = crude_ests(;seed = 1, nulleff = 3)
crude_res = [similar(testdat) for k in 1:1000]

# get crude results
for k in 1:1000
    crude_res[k] = crude_ests(;seed = mod(k, 1000), nulleff = 1)
end

# concatenate
cruderes = reduce(vcat,crude_res)

# write
CSV.write("sim2_crude.csv", cruderes)
# CSV.write("Code/simulations/sim2_regen/results/sim2_crude.csv", cruderes)