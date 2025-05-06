#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --exclusive
#SBATCH --constraint="e7543"
#SBATCH --mem=247g
#SBATCH --gres=lscratch:5
#=
module load julia
export JULIA_NUM_THREADS=64
srun julia --threads 64 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using CSV
using DataFrames
using Distributions
using MultistateModels
using PrettyTables
using StatsBase

include("sim_funs.jl")
# include("sim1_illnessdeath/sim_funs.jl")

# simulate paths
nests = 8
ntasks = 64
inner = 50
outer = inner * ntasks
ests = zeros(nests, outer)
seqs = [collect(1:inner) .+ inner * (k-1) for k in 1:ntasks]

Threads.@threads for k in 1:length(seqs)

    println(k)
    
    # summarize
    for j in 1:inner
        sim_mod = setup_model(; make_pars = true, data = nothing, family = "wei", nsubj = 250)
    
        # simulate paths
        paths_sim = simulate(sim_mod; nsim = 40, paths = true, data = false)

        # summarize
        ests[:,seqs[k][j]] = reduce(vcat, collect(get_estimates(paths_sim)))
    end
end 

# summarize estimates
true_vals = vec(mapslices(x -> mean(x), ests, dims = [2,]))

truth = DataFrame(Quantity = ["PFS", 
                              "Pr(progression)",
                              "Pr(death w/ progression)",
                              "Pr(death w/o progression)",
                              "RMPFST",
                              "Time to prog. given prog.",
                              "Time to prog. or EoF",
                              "Illness duration"],
                  Truth = true_vals)

CSV.write("true_vals.csv", truth)
