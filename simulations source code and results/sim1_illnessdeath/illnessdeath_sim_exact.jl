
# # get command line arguments
simnum, seed, family, ntimes, sims_per_subj, nboot = parse.(Int64, ARGS)

# get functions
include("sim_funs_exact.jl")

# # run the simulation
results = work_function(;simnum = simnum, seed = seed, family = family, ntimes = ntimes, sims_per_subj = sims_per_subj, nboot = nboot)

# save results
using BSON
bson("/data/fintzijr/multistate/sim1_illnessdeath/illnessdeath_exact_$simnum.bson", Dict(:results => results))
