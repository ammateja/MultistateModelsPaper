include("sim1_illnessdeath/slurm_scripts/swarm_helpers.jl")

# for testing
make_swarm(;
    jobids = [collect(1:3000); collect(4001:7000); collect(8001:11000)],
    sims_per_subj = 20,
    nboot = 1000,
    jobname = "illnessdeath_sim_exact.jl",
    swarmname = "illnessdeath_f123.swarm", 
    callname = "runswarm_f123.txt")

make_swarm(;
    jobids = collect(3001:4000),
    sims_per_subj = 20,
    nboot = 1000,   
    jobname = "illnessdeath_sim_exact.jl",
    swarmname = "illnessdeath_f4n6.swarm", 
    callname = "runswarm_f4n6.txt")

make_swarm(;
    jobids = collect(7001:8000),
    sims_per_subj = 20,
    nboot = 1000,   
    jobname = "illnessdeath_sim_exact.jl",
    swarmname = "illnessdeath_f4n12.swarm", 
    callname = "runswarm_f4n12.txt")

make_swarm(;
    jobids = collect(11001:12000),
    sims_per_subj = 20,
    nboot = 1000,
    jobname = "illnessdeath_sim_exact.jl",
    swarmname = "illnessdeath_f4n4.swarm", 
    callname = "runswarm_f4n4.txt")




# for testing
make_swarm(;
    jobids = [collect(1:1000); collect(4001:5000); collect(8001:9000)],
    sims_per_subj = 20,
    nboot = 1000,
    swarmname = "illnessdeath_exp.swarm", 
    callname = "runswarm_exp.txt")

make_swarm(;
jobids = collect(1:3000),
sims_per_subj = 20,
nboot = 1000,
jobname = "illnessdeath_sim_exact.jl",
swarmname = "illnessdeath_f1.swarm", 
callname = "runswarm_f1.txt")

make_swarm(;
jobids = collect(4001:7000),
sims_per_subj = 20,
nboot = 1000,
jobname = "illnessdeath_sim_exact.jl",
swarmname = "illnessdeath_f2.swarm", 
callname = "runswarm_f2.txt")

make_swarm(;
jobids = collect(8001:11000),
sims_per_subj = 20,
nboot = 1000,
jobname = "illnessdeath_sim_exact.jl",
swarmname = "illnessdeath_f3.swarm", 
callname = "runswarm_f3.txt")