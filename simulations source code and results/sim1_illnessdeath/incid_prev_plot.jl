using BSON
using Plots

include(joinpath("sim1_illnessdeath", "sim_funs.jl"))

# make model
Random.seed!(52787)
model_sim = setup_model(; make_pars = true, data = nothing, family = "wei", nsubj = 200)
        
# simulate paths
paths = simulate(model_sim; nsim = 1, paths = true, data = false)
dat = reduce(vcat, map(x -> observe_subjdat(x, model_sim), paths))

# get spline knots
spknots1 = (knots12 = [0.0; quantile(MultistateModels.extract_sojourns(1, 2, MultistateModels.extract_paths(dat)), [0.5, 1.0])],
            knots13 = [0.0; quantile(MultistateModels.extract_sojourns(1, 3, MultistateModels.extract_paths(dat)), [0.5, 1.0])],
            knots23 = [0.0; quantile(MultistateModels.extract_sojourns(2, 3, MultistateModels.extract_paths(dat)), [0.5, 1.0])])

spknots2 = (knots12 = [0.0; quantile(MultistateModels.extract_sojourns(1, 2, MultistateModels.extract_paths(dat)), [1/3, 2/3, 1.0])],
            knots13 = [0.0; quantile(MultistateModels.extract_sojourns(1, 3, MultistateModels.extract_paths(dat)), [1/3, 2/3, 1.0])],
            knots23 = [0.0; quantile(MultistateModels.extract_sojourns(2, 3, MultistateModels.extract_paths(dat)), [1/3, 2/3, 1.0])])

# models for fitting
model_exp = setup_model(;make_pars = false, data = dat, family = "exp")
model_wei = setup_model(;make_pars = false, data = dat, family = "wei")
model_sp1 = setup_model(;make_pars = false, data = dat, family = "sp1", spknots = spknots1)
model_sp2 = setup_model(;make_pars = false, data = dat, family = "sp2", spknots = spknots2)

# fit models
exp_fitted = fit(model_exp)
wei_fitted = fit(model_wei; α = 0.2, γ = 0.2, tol = 0.01)
sp1_fitted = fit(model_sp1; α = 0.2, γ = 0.2, tol = 0.01)
sp2_fitted = fit(model_sp2; α = 0.2, γ = 0.2, tol = 0.01)
