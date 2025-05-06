using Plots
ests_trace = zeros(14, 1000)
for k in 1:1000
    ests_trace[:,k] = collect(summarize_paths(paths_sim[:,1:k], model_sim.data))
end





using Symbolics
@variables λ β
z = λ * exp(β) * exp(-λ * exp(β)) * λ * exp(-λ)
hes = simplify.(Symbolics.hessian(z, [λ, β]))

V = substitute.(hes, (Dict(λ => 1.0, β => π),))

d = (λ^4)*exp(3β - λ - λ*exp(β)) + 2(λ^2)*exp(β - λ - λ*exp(β)) + 4(λ^2)*exp(2β - λ - λ*exp(β)) - (λ^3)*(exp(2β - λ - λ*exp(β)) + exp(3β - λ - λ*exp(β))) - 2λ*exp(β - λ - λ*exp(β)) - 3(λ^3)*exp(2β - λ - λ*exp(β))

substitute.(hes, (Dict(λ => exp(-0.014021627710417815), β => 0.0067),))
substitute.(d, (Dict(λ => exp(-0.014021627710417815), β => 0.0067),))

plot(1.5, substitute.(d, (Dict(λ => 1.5, β => π),))[1])
for k in 0.0:0.001:5.0 plot!(k, substitute.(d, (Dict(λ => k, β => π),))) 
plot(collect(0.0:0.001:5.0), substitute.(d, (Dict(λ => (collect(0.0:0.001:5.0)), β => π),)))

### experiment with try-catch
function tryit()
    try
        # fit model
        println("Fitting model for job $jobind.")
        fitted = fit(model_fit, verbose = true)

        # move the parameters over to the model for simulation
        set_parameters!(model_sim, fitted.parameters)

        ### simulate from the fitted model
        paths_sim = simulate(model_sim; nsim = sims_per_subj, paths = true, data = false)

        ### process the results
        estimates = summarize_paths(paths_sim, model_sim.data)
        
        # return for assignment
        return (fitted.parameters, fitted.vcov, estimates)
    catch err
        return (missing, missing, missing)
    end
end

######### Additional code for observe_subjdat

# # make the dataset
# if symp & !pcr & !sero
#     # determine whether participant had symptomatic covid
#     covid = 6 ∈ path.states

#     # 1 = naive, 2 = symptomatic covid
#     subjdat = DataFrame(id = subj_dat.id[1],
#                         tstart = 0.0, 
#                         tstop = covid ? path.times[findfirst(path.states .== 6)] : last(subj_dat.tstop),
#                         statefrom = 1,
#                         stateto = covid ? 2 : 1,
#                         obstype = 1,
#                         mab = subj_dat.mab[1])

# elseif !symp & pcr & !sero
#     # 1 = naive, 2 = PCR+, 3 = PCR-
#     path.states[findall(path.states .∈ Ref([2,3,6,7]))] .= 2
#     path.states[findall(path.states .∈ Ref([4,5,8,9]))] .= 3

#     # state sequence at observation times
#     stateseq = observe_path(path, [0.0; subj_dat.tstop])

#     # data frame
#     subjdat = copy(subj_dat)
#     subjdat.stateto = stateseq[Not(1)]
#     subjdat.statefrom[Not(1)] = subjdat.stateto[Not(end)]
    
# elseif !symp & !pcr & sero

#     # 1 = naive, 2 = seroconvert
#     subjdat = DataFrame(id = subj_dat.id[1],
#                         tstart = 0.0, 
#                         tstop = last(subj_dat.tstop),
#                         statefrom = 1,
#                         stateto = last(path.states) ∈ [4,5,8,9] ? 2 : 1,
#                         obstype = 2,
#                         mab = subj_dat.mab[1])        

# elseif symp & pcr & !sero
    
#     # collapse across serology within PCR x infection
#     path.states[findall(path.states .∈ Ref([3,5]))] = path.states[findall(path.states .∈ Ref([3,5]))] .- 1

#     path.states[findall(path.states .∈ Ref([7,9]))] = path.states[findall(path.states .∈ Ref([7,9]))] .- 1

#     # renumber
#     path.states[findall(path.states .== 4)] .= 3
#     path.states[findall(path.states .== 6)] .= 4
#     path.states[findall(path.states .== 8)] .= 5

#     # state sequence at observation times
#     times  = [0.0; subj_dat.tstop]
#     if any(path.states .== 4)
#         push!(path.times[findfirst(path.states .== 4)])
#         sort!(times)
#     end
#     states = observe_path(path, times)

#     # data frame
#     subjdat = DataFrame(id = fill(path.subj, length(times) - 1),
#                         tstart = times[Not(end)],
#                         tstop = times[Not(1)],
#                         statefrom = states[Not(end)],
#                         stateto = states[Not(1)],
#                         obstype = fill(2, length(times) - 1),
#                         mab = fill(subj_dat.mab[1], length(times) - 1))

#     # correct obstype for symptomatic covid
#     subjdat.obstype[subjdat.stateto .== 4] .= 1

# elseif symp & !pcr & sero
#     # determine whether participant had symptomatic covid
#     path.states[findall(path.states .∈ Ref([2,4]))] .= 1
#     path.states[findall(path.states .∈ Ref([3,5]))] .= 2
#     path.states[findall(path.states .∈ Ref([6,8]))] .= 3
#     path.states[findall(path.states .∈ Ref([7,9]))] .= 4

#     # state sequence at observation times
#     times  = [0.0; last(subj_dat.tstop)]
#     if any(path.states .== 3)
#         push!(path.times[findfirst(path.states .== 3)])
#         sort!(times)
#     end
#     states = observe_path(path, times)

#     # data frame
#     subjdat = DataFrame(id = fill(path.subj, length(times) - 1),
#                         tstart = times[Not(end)],
#                         tstop = times[Not(1)],
#                         statefrom = states[Not(end)],
#                         stateto = states[Not(1)],
#                         obstype = fill(2, length(times) - 1),
#                         mab = fill(subj_dat.mab[1], length(times) - 1))

#     # correct obstype for symptomatic covid
#     subjdat.obstype[subjdat.stateto .== 3] .= 1

# elseif symp &  pcr &  sero