#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-3:00:00
#SBATCH --ntasks=36
#SBATCH --ntasks-per-core=1
#SBATCH --constraint=x6140
#SBATCH --exclusive
#SBATCH --mem=247g
#SBATCH --gres=lscratch:25
#=
module load julia
srun julia $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using ArraysOfArrays
using Chain
using CSV
using DataFrames
using Distributions
using LinearAlgebra
using MultistateModels
using RCall
using StatsBase
using Random

R"if (!require('survival', quietly=TRUE)) install.packages('survival')"
R"if (!require('binom', quietly=TRUE)) install.packages('binom')"

@rlibrary binom
@rlibrary survival

# include("sim_funs.jl")
# seeds = collect(1:1000)

include("sim1_illnessdeath/sim_funs.jl")
seeds = collect(1:1000)

# initialize matrix with results
ests_crude = [DataFrame() for j in [4, 6, 12] for k in eachindex(seeds)]
sims = [[k,j] for j in [4, 6, 12] for k in eachindex(seeds)]

for i in eachindex(sims)
    ests_crude[i] = crude_ests(;seed = sims[i][1], ntimes = sims[i][2])
end

# save
CSV.write(joinpath("sim1_illnessdeath", "illnessdeath_crude.csv"), reduce(vcat, ests_crude))