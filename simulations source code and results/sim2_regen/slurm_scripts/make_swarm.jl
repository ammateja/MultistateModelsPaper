include("sim2_regen/slurm_scripts/swarm_helpers.jl")

# runswarm_full1
make_swarm_full1(; sims = collect(1:1000), nulleffs = 1)

# runswarm_full2
# make_swarm_full2(; sims = collect(1:1000), nulleffs = 1)

# runswarm_full1
using DataFrames
nsim = 1000
binsize = 250
istart = 0
cjobs = DataFrame(j = Int64.(collect(1:(nsim / binsize))))
cjobs[:,:start] = istart .+ (cjobs.j .- 1) .* binsize .+ 1
cjobs[:,:stop]  = istart .+ cjobs.j .* binsize
cjobs[:,:modelnum] .= 4
cjobs[:,:nulleff] .= 1

for k in 1:nrow(cjobs)
    make_swarm_collapsed(; sims = collect(cjobs.start[k]:cjobs.stop[k]), boots = collect(0:1000), model_numbers = cjobs.modelnum[k], nulleffs = cjobs.nulleff[k], swarmname = "regen_sim_collapsed_$(cjobs.start[k]).$(cjobs.stop[k]).$(cjobs.modelnum[k]).$(cjobs.nulleff[k]).swarm", callname = "runswarm_collapsed_$(cjobs.start[k]).$(cjobs.stop[k]).$(cjobs.modelnum[k]).$(cjobs.nulleff[k]).txt")
end

make_swarm_collapsed(; sims = collect(1:1000), boots = collect(0:200), model_numbers = 3, nulleffs = 1, swarmname = "regen_sim_collapsed_3.swarm", callname = "runswarm_collapsed_3.txt")