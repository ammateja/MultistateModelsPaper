using DataFrames
using Distributions
using MultistateModels
using RCall
using Plots

include("sim1_illnessdeath/sim_funs.jl")

# setup model and summarize to find parameter values for simulation
nsubj = 10000

# create hazards
# 1: healthy
# 2: sick
# 3: dead
h12 = Hazard(@formula(0 ~ 1), "wei", 1, 2)
h13 = Hazard(@formula(0 ~ 1), "wei", 1, 3)
h23 = Hazard(@formula(0 ~ 1), "wei", 2, 3)

# data for simulation parameters
dat = DataFrame(id = collect(1:(nsubj)),
                tstart = zeros(Float64, nsubj),
                tstop = fill(1.0, nsubj),
                statefrom = fill(1, nsubj),
                stateto = fill(1, nsubj),
                obstype = fill(1, nsubj))

# create model
model = multistatemodel(h12, h13, h23; data = dat)
set_parameters!(model,
               (h12 = [log(1.25), log(2)],
                h13 = [log(1.25), log(1)],
                h23 = [log(1.25), log(2)]))


# plot curves
# plot(collect(0:0.01:1), compute_hazard(collect(0:0.01:1), model, :h12))   # 1->2
# plot!(collect(0:0.01:1), compute_hazard(collect(0:0.01:1), model, :h13))   # 1->3
# plot!(collect(0:0.01:1), compute_hazard(collect(0:0.01:1), model, :h23))   # 2->3

plot(collect(0.01:0.01:1), cumulative_incidence(collect(0:0.01:1), model, model.parameters, 1, 1))   # 1->2
# plot!(collect(0.01:0.01:1), cumulative_incidence(collect(0:0.01:1), model, model.parameters, 2, 1))   # 1->2

# simulate paths
paths = simulate(model; paths = true, data = false)

get_estimates(paths)

