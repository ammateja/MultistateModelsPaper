# load packages
using BSON
using Chain
using CSV
using DataFrames
using DataFramesMeta
using MIMEs
using MultistateModels
using Plots
using PrettyTables
using StatsBase

# import true values
truth = CSV.read(joinpath("sim1_illnessdeath", "true_vals.csv"), DataFrame)
    
# load crude estimates
crude = CSV.read(joinpath("sim1_illnessdeath", "illnessdeath_crude.csv"), DataFrame)
    
# multistate results
msm_results = CSV.read(joinpath("sim1_illnessdeath", "illnessdeath_results_full.csv"), DataFrame)

# rename var
setvars(x) = x == "pfs" ? "PFS" :
           x == "prog" ? "Pr(progression)" :
           x == "die_wprog" ? "Pr(death w/ progression)" : 
           x == "die_noprog" ? "Pr(death w/o progression)" : 
           x == "rmpfst" ? "RMPFST" :
           x == "time2prog" ? "Time to progression" : 
           x == "time2prog_gprog"  ? "Time to prog. given prog." :
           x == "time2prog_all" ? "Time to prog. or EoF" :
           x == "illnessdur" ? "Illness duration"  : string(x)

setmethod(x) = x == 0 ? "Crude" : 
               x == 1 ? "Markov" : 
               x == 2 ? "Weibull" : 
               x == 3 ? "Linear splines" : 
               x == 4 ? "Natural cubic splines" : string(x)

truth.Quantity = setvars.(truth.Quantity)
crude.var = setvars.(crude.var)
msm_results.var = setvars.(msm_results.var)
                            
# summarize crude estimates
cruderes = @chain copy(crude) begin
    @select($(Not(:simnum)))
    @rename(:Quantity = :var, :est = :ests)
    leftjoin(truth, on = :Quantity)
    @transform begin
        :bias = (:est .- :Truth) ./ :Truth
        :coverage = (:Truth .> :lower) .& (:Truth .< :upper)
        :ciw  = (:upper .- :lower) ./ :Truth
    end
    @by [:ntimes, :Quantity] begin
        :bias = round.(mean(:bias), digits = 2)
        :coverage = round(mean(:coverage), digits = 2)
        :ciw = round(mean(:ciw), digits = 2)
    end
    @transform(:method = 0)
    select(:method, Not(:method))
end

# summarize msm estimates
msmres = @chain copy(msm_results) begin
    @select($(Not(:simnum)))
    @rename(:Quantity = :var, :est = :ests, :method = :family)
    leftjoin(truth, on = :Quantity)
    @transform begin
        :bias = (:est .- :Truth) ./ :Truth
        :coverage = (:Truth .> :lower) .& (:Truth .< :upper)
        :ciw  = (:upper .- :lower) ./ :Truth
    end
    @by [:ntimes, :method, :Quantity] begin
        :bias = round.(mean(:bias), digits = 2)
        :coverage = round(mean(:coverage), digits = 2)
        :ciw = round(mean(:ciw), digits = 2)
    end
end

# stack
res = vcat(cruderes, msmres)

res = @chain res begin
    @subset(:Quantity .∈ Ref(["RMPFST", "Time to prog. given prog.", "Time to prog. or EoF", "Illness duration"]))
    @subset(:ntimes .!= 6)
    @orderby(:ntimes, :Quantity, :method)
end

res.method = setmethod.(res.method)


# tables for main text
reswide = @chain res begin
    stack([:bias, :coverage, :ciw])
    @transform(:colkey = :Quantity .* " " .* :variable)
    unstack([:method, :ntimes], :colkey, :value)
    select(Not(:ntimes))
end
reswide = reswide[:,[1, 3, 7, 11, 5, 9, 13, 4, 8, 12, 2, 6, 10]]
rename!(reswide, [:Method, :Bias, :Covg, :CIW, :Bias, :Covg, :CIW, :Bias, :Covg, :CIW, :Bias, :Covg, :CIW], makeunique = true)

pretty_table(reswide; backend = Val(:latex))

# hcat 
reswide = vcat(hcat(res_bygroup[2][:,[1,4,5,6]], 
               res_bygroup[1][:,[4,5,6]], 
               res_bygroup[3][:,[4,5,6]], makeunique = true),
               hcat(res_bygroup[4][:,[1,4,5,6]], 
               res_bygroup[5][:,[4,5,6]], 
               res_bygroup[6][:,[4,5,6]], makeunique = true))

# print latex tables
show(stdout, MIME("text/latex"), reswide)

# test
testres = @chain msm_results begin
    @subset(:family .== 1)
    @subset(:ntimes .== 4)
    @subset(:var .== "Time to progression")
    @rename(:Quantity = :var, :est = :ests, :method = :family)
    leftjoin(truth, on = :Quantity)
end

mean((testres.est .- testres.Truth) ./ testres.Truth)
mean((testres.lower .<= testres.Truth) .& (testres.upper .> testres.Truth))
mean((testres.upper .- testres.lower) ./ testres.Truth)

gres = @chain msmres begin
    groupby([:ntimes, :Quantity, :method])
end

mean(gres[6].coverage .== true)