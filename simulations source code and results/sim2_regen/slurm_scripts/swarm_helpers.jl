# job directory
using DataFrames

#### full model 1
# function to make the grid
function make_jobs_full1(;sims, nulleffs, jobname, swarmname)
    
    # remove the existing file
    if isfile(swarmname)
        rm(swarmname)
    end

    # jobgrid
    jobs = reduce(vcat, [[s1 s2 y z] for s1 in sims for s2 in 0 for y in 1 for z in nulleffs])

    # write jobs to swarm file
    open(swarmname, "a") do file
        for j in 1:size(jobs, 1)
            # append to file
            open(swarmname, "a") do file
                write(file, join(["julia"; jobname; jobs[j, 1]; jobs[j, 2]; jobs[j,3]; jobs[j,4]; "\n"], " "))
            end
        end
    end    
end

function make_swarmcall_full1(swarmname, callname) 
    # remove the call script if it exists
    if isfile(callname)
        rm(callname)
    end

    flags = join(
        ["--module julia",
        "--noht",# no hyperthreading (tasks per core = 1)
        "--merge-output",
        "--logdir ./swarmlogs",
        # "-b $bundlesize",
        # "-t 2", # allocate node exclusively
        "-g 20", # mem per task
        "--time-per-subjob=00-04:00:00",
        "--partition=norm,quick", 
        raw"--sbatch '--constraint=ibhdr100'"]," ")
    # submit
    open(callname, "a") do file
        write(file, join(["swarm"; flags; swarmname], " "))
    end
end

function make_swarm_full1(;sims, nulleffs, jobname = "regen_sim.jl", swarmname = "regen_sim_full1.swarm", callname = "runswarm_full1.txt", filepath = pwd()*"/sim2_regen/slurm_scripts/")
    
    # alias the functions to make the swarm call and job
    make_swarmcall_full1(swarmname, filepath * callname);

    make_jobs_full1(;sims = sims, nulleffs = nulleffs, jobname = jobname, swarmname = filepath * swarmname);
end

#### full model 2
# function to make the grid
function make_jobs_full2(;sims, nulleffs, jobname, swarmname)
    
    # remove the existing file
    if isfile(swarmname)
        rm(swarmname)
    end

    # jobgrid
    jobs = reduce(vcat, [[s1 s2 y z] for s1 in sims for s2 in 0 for y in 2 for z in nulleffs])

    # write jobs to swarm file
    open(swarmname, "a") do file
        for j in 1:size(jobs, 1)
            # append to file
            open(swarmname, "a") do file
                write(file, join(["julia"; jobname; jobs[j, 1]; jobs[j, 2]; jobs[j,3]; jobs[j,4]; "\n"], " "))
            end
        end
    end    
end

function make_swarmcall_full2(swarmname, callname) 
    # remove the call script if it exists
    if isfile(callname)
        rm(callname)
    end

    flags = join(
        ["--module julia",
        "--noht",# no hyperthreading (tasks per core = 1)
        "--merge-output",
        "--logdir ./swarmlogs",
        # "-b $bundlesize",
        # "-t 2", # allocate node exclusively
        "-g 30", # mem per task
        "--time-per-subjob=10-00:00:00",
        "--partition norm", 
        raw"--sbatch '--constraint=ibhdr100'"]," ")
    # submit
    open(callname, "a") do file
        write(file, join(["swarm"; flags; swarmname], " "))
    end
end

function make_swarm_full2(;sims, nulleffs, jobname = "regen_sim.jl", swarmname = "regen_sim_full2.swarm", callname = "runswarm_full2.txt", filepath = pwd()*"/sim2_regen/slurm_scripts/")
    
    # alias the functions to make the swarm call and job
    make_swarmcall_full2(swarmname, filepath * callname);

    make_jobs_full2(;sims = sims, nulleffs = nulleffs, jobname = jobname, swarmname = filepath * swarmname);
end


#### collapsed models
# function to make the grid
function make_jobs_collapsed(;sims, boots, model_numbers, nulleffs, jobname, swarmname)
    
    # remove the existing file
    if isfile(swarmname)
        rm(swarmname)
    end

    # jobgrid
    jobs = reduce(vcat, [[s1 s2 y z] for s1 in sims for s2 in boots for y in model_numbers for z in nulleffs])

    # write jobs to swarm file
    open(swarmname, "a") do file
        for j in 1:size(jobs, 1)
            # append to file
            open(swarmname, "a") do file
                write(file, join(["julia"; jobname; jobs[j, 1]; jobs[j, 2]; jobs[j,3]; jobs[j,4]; "\n"], " "))
            end
        end
    end    
end

function make_swarmcall_collapsed(swarmname, callname) 
    # remove the call script if it exists
    if isfile(callname)
        rm(callname)
    end

    flags = join(
        ["--module julia",
        "--noht",# no hyperthreading (tasks per core = 1)
        "--merge-output",
        "--logdir ./swarmlogs",
        # "-b $bundlesize",
        # "-t 2", # allocate node exclusively
        "-g 8", # mem per task
        "--time-per-subjob=10-00:00:00",
        "--partition=norm", 
        raw"--sbatch '--constraint=ibhdr100'"]," ")
    # submit
    open(callname, "a") do file
        write(file, join(["swarm"; flags; swarmname], " "))
    end
end

function make_swarm_collapsed(;sims, boots, model_numbers, nulleffs, jobname = "regen_sim.jl", swarmname = "regen_sim_collapsed.swarm", callname = "runswarm_collapsed.txt", filepath = pwd()*"/sim2_regen/slurm_scripts/")
    
    # alias the functions to make the swarm call and job
    make_swarmcall_collapsed(swarmname, filepath * callname);

    make_jobs_collapsed(;sims = sims, boots = boots, model_numbers = model_numbers, nulleffs = nulleffs, jobname = jobname, swarmname = filepath * swarmname);
end
