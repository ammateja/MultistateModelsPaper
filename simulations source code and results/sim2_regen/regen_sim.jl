
# get command line arguments
seed1, seed2, model_number, nulleff = parse.(Int64, ARGS)

if !isfile("/data/fintzijr/multistate/sim2_regen/regen_sim_results_$seed1.$seed2.$model_number.$nulleff.bson")
    # get functions
    include("sim_funs.jl")

    # run the simulation
    results = work_function(;seed1, seed2, model_number, nulleff)

    # save results
    using BSON
    # jason to put his own directory instead
    bson("/data/fintzijr/multistate/sim2_regen/regen_sim_results_$seed1.$seed2.$model_number.$nulleff.bson", Dict(:results => results))
end
