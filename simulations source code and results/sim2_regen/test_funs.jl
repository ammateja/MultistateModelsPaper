nulleff=1

# set up model for simulation
model_full_sim = setup_full_model(; make_pars = true, data = nothing, nulleff = nulleff)
    
# simulate paths
paths = simulate(model_full_sim; nsim = 1, paths = true, data = false)[:,1]

# test observe subjdat functions
ninfec = sum(map(x -> any(x.states .> 1), paths))
nsympt = sum(map(x -> any(x.states .> 5), paths))
nsero = sum(map(x -> any(x.states .∈ Ref([3,5,7,9])), paths))
rmt_i = mean(map(x -> any(x.states .> 1) ? x.times[findfirst(x.states .> 1)] : 4.0, paths))

# make dataset
dat1 = reduce(vcat, map(x -> observe_subjdat(x, model_full_sim, 1), paths))
dat2 = reduce(vcat, map(x -> observe_subjdat(x, model_full_sim, 2), paths))
dat3 = reduce(vcat, map(x -> observe_subjdat(x, model_full_sim, 3), paths))

# set up full model and summarize paths
model1 = setup_full_model(; make_pars = false, data = make_dat4pred(dat1))
ests1 = summarize_paths_full(paths, model1)

# set up full model and summarize paths
model2 = setup_full_model(; make_pars = false, data = make_dat4pred(dat2))
ests2 = summarize_paths_full(paths, model2)

# set up sero models
# get N+ and N-
dat_npos = @subset(dat3, :sero .== true)
dat_nneg = @subset(dat3, :sero .== false)

paths_collapsed = collapse_path.(deepcopy(paths))

rmt_i3 = mean(map(x -> any(x.states .> 1) ? x.times[findfirst(x.states .> 1)] : 4.0, paths_collapsed))

paths_npos = paths_collapsed[map(x -> x.subj .∈ Ref(unique(dat3.id[dat3.sero .== true])), paths_collapsed)]
paths_nneg = paths_collapsed[map(x -> x.subj .∈ Ref(unique(dat3.id[dat3.sero .== false])), paths_collapsed)]

# recode subject IDs
dat_npos.id = indexin(dat_npos.id, unique(dat_npos.id))
dat_nneg.id = indexin(dat_nneg.id, unique(dat_nneg.id))

model_npos = setup_collapsed_model(; make_pars = false, data = make_dat4pred(dat_npos), model_number = 3)
model_nneg = setup_collapsed_model(; make_pars = false, data = make_dat4pred(dat_nneg), model_number = 3)

ests3 = summarize_paths_collapsed(paths_npos, paths_nneg, model_npos, model_nneg)

a12 = abs.(reduce(vcat, collect(ests1) .- collect(ests2)))
a13 = abs.(reduce(vcat, collect(ests1) .- collect(ests3)))
maximum(a12)
maximum(a13)

summarize_paths_full(paths, model2; return_counts = true)
summarize_paths_collapsed(paths_npos, paths_nneg, model_npos, model_nneg; return_counts = true)