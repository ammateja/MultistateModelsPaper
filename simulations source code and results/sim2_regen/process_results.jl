# load packages
using BSON
using Chain
using CSV
using DataFrames
using DataFramesMeta
using mime
using MultistateModels
using Plots
using PrettyTables
using StatsBase

# import true values
truth_regen = CSV.read("sim2_regen/results/true_vals.csv", DataFrame)

 # round true values
truth = @chain truth_regen begin @select(:Quantity, :Truth) end

# load crude estimates
crude = CSV.read("sim2_regen/results/sim2_crude.csv", DataFrame)

# multistate results
# 1 = continuously observed, generative model
# 2 = panel data + symptom onset, generative model
# 3 = panel data + symptom onset, collapsed model
# 4 = panel data + symptom onset, first order splines
msm_results1 = CSV.read("sim2_regen/results/regensim_results_1.csv", DataFrame)
msm_results2 = CSV.read("sim2_regen/results/regensim_results_2.csv", DataFrame)
msm_results3 = CSV.read("sim2_regen/results/res_new/regensim_results_3.csv", DataFrame)
msm_results4 = CSV.read("sim2_regen/results/res_new/regensim_results_4.csv", DataFrame)

# rename var
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
           x ∈ ["rmt_i_m", "rmti_m"] ? "RMTI | mAb" : 
           x ∈ ["rmt_i_p", "rmti_p"] ? "RMTI | Plac." : 
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

truth.Quantity = setvars.(truth.Quantity)
msm_results1.var = setvars.(msm_results1.var)
msm_results2.var = setvars.(msm_results2.var)
msm_results3.var = setvars.(msm_results3.var)
msm_results4.var = setvars.(msm_results4.var)
                            
# summarize crude estimates
cruderes = @chain copy(crude) begin
    @subset(:nulleff .== 1)
    @select($(Not(:nulleff, :seed, :cens)))
    @rename(:Quantity = :var)
    leftjoin(truth, on = :Quantity)
    @rtransform begin
        :bias = (:est - :Truth) / :Truth
        :coverage = (:Truth > :lower) & (:Truth < :upper)
        :ciw  = (:upper - :lower) / :Truth
    end
    groupby(:Quantity)
    @combine($AsTable = (bias = round.(mean(:bias), digits = 2),
                         coverage = round(mean(:coverage), digits = 2),
                         ciw = round(mean(:ciw), digits = 2)))
    @transform(:method = "crude")
    select(:method, Not(:method))
end

# summarize msm estimates
msmres1 = @chain copy(msm_results1) begin
    @select($(Not(:nulleff, :seed1, :seed2, :model_number)))
    @rename(:Quantity = :var, :est = :ests)
    leftjoin(truth, on = :Quantity)
    @rtransform begin
        :bias = (:est - :Truth) / :Truth
        :coverage = (:Truth > :lower) & (:Truth < :upper)
        :ciw  = (:upper - :lower) / :Truth
    end
    groupby(:Quantity)
    @combine($AsTable = (bias = round.(mean(:bias), digits = 2),
                         coverage = round(mean(:coverage), digits = 2),
                         ciw = round(mean(:ciw), digits = 2)))
    @transform(:method = "multistate_full")
    select(:method, Not(:method))
end

msmres2 = @chain copy(msm_results2) begin
    @select($(Not(:nulleff, :seed1, :seed2, :model_number)))
    @rename(:Quantity = :var, :est = :ests)
    leftjoin(truth, on = :Quantity)
    @rtransform begin
        :bias = (:est - :Truth) / :Truth
        :coverage = (:Truth > :lower) & (:Truth < :upper)
        :ciw  = (:upper - :lower) / :Truth
    end
    groupby(:Quantity)
    @combine($AsTable = (bias = round.(mean(:bias), digits = 2),
                         coverage = round(mean(:coverage), digits = 2),
                         ciw = round(mean(:ciw), digits = 2)))
    @transform(:method = "multistate_panel")
    select(:method, Not(:method))
end

msmres3 = @chain copy(msm_results3) begin
    @groupby(Cols(:simnum, :var))
    @combine begin 
        :est = mean(:est)
        :lower = quantile(:est, 0.025)
        :upper = quantile(:est, 0.975)
    end
    @rename(:Quantity = :var)
    leftjoin(truth, on = :Quantity)
    @rtransform begin
        :bias = (:est - :Truth) / :Truth
        :coverage = (:Truth > :lower) & (:Truth < :upper)
        :ciw  = (:upper - :lower) / :Truth
    end
    groupby(:Quantity)
    @combine($AsTable = (bias = round.(mean(:bias), digits = 2),
                         coverage = round(mean(:coverage), digits = 2),
                         ciw = round(mean(:ciw), digits = 2)))
    @transform(:method = "collapsed1")
    select(:method, Not(:method))
end


msmres4 = @chain copy(msm_results4) begin
    @groupby(Cols(:simnum, :var))
    @combine begin 
        :est = mean(:est)
        :lower = quantile(:est, 0.025)
        :upper = quantile(:est, 0.975)
    end
    @rename(:Quantity = :var)
    leftjoin(truth, on = :Quantity)
    @rtransform begin
        :bias = (:est - :Truth) / :Truth
        :coverage = (:Truth > :lower) & (:Truth < :upper)
        :ciw  = (:upper - :lower) / :Truth
    end
    groupby(:Quantity)
    @combine($AsTable = (bias = round.(mean(:bias), digits = 2),
                         coverage = round(mean(:coverage), digits = 2),
                         ciw = round(mean(:ciw), digits = 2)))
    @transform(:method = "collapsed2")
    select(:method, Not(:method))
end

# stack
res_regen = vcat(msmres2, msmres3, msmres4, cruderes)

# tables for main text
res_bygroup = groupby(res_regen, :method)

# combine
pe = hcat(res_PE[1][:,2:5], 
          res_PE[2][:,3:5], 
          res_PE[3][:,3:5],
          res_PE[4][:,3:5], makeunique = true)

rr = hcat(res_RR[1][:,2:5], 
          res_RR[2][:,3:5], 
          res_RR[3][:,3:5],
          res_RR[4][:,3:5], makeunique = true)

detec = hcat(res_detec[1][:,2:5], 
          res_detec[2][:,3:5], 
          res_detec[3][:,3:5], makeunique = true)

# print latex tables
show(stdout, MIME("text/latex"), pe)
show(stdout, MIME("text/latex"), rr)
show(stdout, MIME("text/latex"), detec)


res_PE = groupby(res_regen[findall(sum(reduce(hcat, [occursin.(x, res_regen.Quantity) for x in ["PE"]]), dims = 2)[:,1] .== 1), :], :method)
res_RR = groupby(res_regen[findall(sum(reduce(hcat, [occursin.(x, res_regen.Quantity) for x in ["RR"]]), dims = 2)[:,1] .== 1), :], :method)
res_detec = groupby(res_regen[findall(sum(reduce(hcat, [occursin.(x, res_regen.Quantity) for x in ["RMTI", "RMPCR", "Detected"]]), dims = 2)[:,1] .== 1), :], :method)

# combine
pe = hcat(res_PE[1][:,2:5], 
          res_PE[2][:,3:5], 
          res_PE[3][:,3:5],
          res_PE[4][:,3:5], makeunique = true)

rr = hcat(res_RR[1][:,2:5], 
          res_RR[2][:,3:5], 
          res_RR[3][:,3:5],
          res_RR[4][:,3:5], makeunique = true)

detec = hcat(res_detec[1][:,2:5], 
          res_detec[2][:,3:5], 
          res_detec[3][:,3:5], makeunique = true)

# print latex tables
show(stdout, MIME("text/latex"), pe)
show(stdout, MIME("text/latex"), rr)
show(stdout, MIME("text/latex"), detec)

# for supplement
res_bygroup = groupby(res_regen, :method)

pretty_table(res_bygroup[1][:,Not(1)]; backend = Val(:latex))
pretty_table(res_bygroup[2][:,Not(1)]; backend = Val(:latex))
pretty_table(res_bygroup[3][:,Not(1)]; backend = Val(:latex))
pretty_table(res_bygroup[4][:,Not(1)]; backend = Val(:latex))