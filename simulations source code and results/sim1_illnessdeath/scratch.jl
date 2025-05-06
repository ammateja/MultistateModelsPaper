using MultistateModels 
include("sim1_illnessdeath/sim_funs.jl")

R"if (!require('survival', quietly=TRUE)) install.packages('survival')"
R"if (!require('binom', quietly=TRUE)) install.packages('binom')"

@rlibrary binom
@rlibrary survival

nsubj = 200
model_sim = setup_model(; make_pars = true, data = nothing, family = "wei", nsubj = nsubj)
        
# simulate paths
paths = simulate(model_sim; nsim = 1, paths = true, data = false)
dat = reduce(vcat, map(x -> observe_subjdat(x, model_sim), paths))

# fit exponential model
model_fitted = fit(setup_model(;make_pars = false, data = dat, family = "exp"))

# simulate from fitted model
model_sim2 = setup_model(; make_pars = false, data = model_sim.data, family = "exp", nsubj = nsubj)
set_parameters!(model_sim2, model_fitted.parameters)
paths_fitted = simulate(model_sim2; nsim = 100, paths = true, data = false)

# plot cumulative incidence
delta = 1e-5
cuminc = cumulative_incidence(0.0:delta:1.0, model_fitted, model_fitted.parameters, 1, 1)
1 - sum(sum(cuminc, dims = 2)[:,1] .* delta)

# in R 
times = reshape(map(p -> p.times[2], paths_fitted), length(paths_fitted), 1)[:,1]
statuses = reshape(map(p -> (p.states[2] == 1 ? 0.0 : 1.0), paths_fitted), length(paths_fitted), 1)[:,1]

mean(times)
ests = get_estimates(paths, model_sim)
ests_fitted = get_estimates(paths_fitted, model_sim2)


# get restricted mean survival time
rmst = rcopy(R"sm = survival:::survmean(survfit(Surv($times, $statuses) ~ 1), rmean = 1.0)[[1]][c('rmean', 'se(rmean)')];c(est = sm[1], lower = sm[1] - 1.96 * sm[2], upper = sm[1] + 1.96 * sm[2])")