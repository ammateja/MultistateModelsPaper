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
# include("Code/simulations/sim2_regen/sim_funs.jl")

# simulate paths
ests = zeros(29, 3200)
inner = 50
seqs = [collect(1:inner) .+ inner * (k-1) for k in 1:64]

Threads.@threads for k in 1:length(seqs)
    
    # summarize
    for j in 1:inner
        mod = setup_full_model(; make_pars = true, data = nothing, n_per_arm = 800, nulleff = 1)
    
        # simulate paths
        paths_sim = simulate(mod; nsim = 40, paths = true, data = false)

        # summarize
        ests[:,seqs[k][j]] = reduce(vcat, collect(summarize_paths_full(paths_sim, mod)[:,2]))
    end
end 

# summarize estimates
model = setup_full_model(; make_pars = true, data = nothing, n_per_arm = 800, nulleff = 1)
true_vals = vec(mapslices(x -> mean(x), ests, dims = [2,]))
estnames = summarize_paths_full(simulate(model; paths = true, data = false), model)[:,1]

setvars(x) = x == "i_p" ? "Pr(Infec. | Plac.)" :
           x == "i_m" ? "Pr(Infec. | mAb)" :
           x == "s_m" ? "Pr(Sympt. | mAb)" : 
           x == "s_p" ? "Pr(Sympt. | Plac.)" : 
           x == "a_m" ? "Pr(Asympt. | mAb)" : 
           x == "a_p" ? "Pr(Asympt. | Plac.)" : 
           x == "s_i_p" ? "Pr(Sympt. | Infec., Plac.)" :
           x == "s_i_m" ? "Pr(Sympt. | Infec., mAb)" :
           x == "a_i_p" ? "Pr(Asympt. | Infec., Plac.)" :
           x == "a_i_m" ? "Pr(Asympt. | Infec., mAb)" :
           x == "rmti_m" ? "RMTI | mAb" : 
           x == "rmti_p" ? "RMTI | Plac." : 
           x == "pcrdur_m" ? "RMPCR+ | mAb" : 
           x == "pcrdur_p" ? "RMPCR+ | Plac." : 
           x == "pcrdetect_m" ? "Pr(Detected | mAb)" :
           x == "pcrdetect_p" ? "Pr(Detected | Plac.)" :
           x == "n_i_p" ? "Pr(N+ | Infec., Plac.)" :
           x == "n_i_m" ? "Pr(N+ | Infec., mAb)" :
           x == "n_s_p" ? "Pr(N+ | sympt., Plac.)" :
           x == "n_s_m" ? "Pr(N+ | sympt., mAb)" :
           x ∈ ["n_as_p","n_a_p"] ? "Pr(N+ | asympt., Plac.)" :
           x ∈ ["n_as_m","n_a_m"] ? "Pr(N+ | asympt., mAb)" :
           x == "pe_infec" ? "PE for infec." :
           x == "pe_sym" ? "PE for sympt. infec." :
           x == "pe_asym" ? "PE for asympt. infec." : 
           x == "eff_sym_infec" ? "RR for sympt. | infec." :
           x == "eff_n_infec" ? "RR for N+ | infec." :
           x == "eff_n_sym" ? "RR for N+ | sympt." :
           x == "eff_n_asym" ? "RR for N+ | asympt." : string(x)

truth = DataFrame(Quantity = setvars.(estnames),
                  Truth = true_vals)

CSV.write("true_vals.csv", truth)
# true_vals_trial = CSV.read("true_vals.csv", DataFrame)
# true_vals_trial = CSV.read("Code/simulations/sim2_regen/true_vals.csv", DataFrame)
