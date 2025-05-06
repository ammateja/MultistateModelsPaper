# job directory
using DataFrames

# function to make the grid
function make_jobs(jobids, sims_per_subj, nboot, jobname, swarmname)
    
    # remove the existing file
    if isfile(swarmname)
        rm(swarmname)
    end

    # write jobs to swarm file
    open(swarmname, "a") do file
        for j in jobids
            # index into job grid
            f = j > 8000 ? (j - 8000) : (j > 4000) ? j - 4000 : j
            family = Int64(ceil(f/1000))
            
            # get seed
            seed = mod(j - 1, 1000) + 1

            # number of times
            ntimes = j > 8000 ? 4 : (j > 4000) ? 12 : 6

            # append to file
            open(swarmname, "a") do file
                write(file, join(["julia"; jobname; "$j"; "$seed"; "$family"; "$ntimes"; "$sims_per_subj"; "$nboot"; "\n"], " "))                
            end
        end
    end    
end

function make_swarmcall(swarmname, callname, jobids) 
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
        # "-t 2", 
        "-g 10", # mem per task
        "--time-per-subjob=0-04:00:00",
        "--partition quick",
        raw"--sbatch '--constraint=ibhdr100'"], " ")
    # submit
    open(callname, "a") do file
        write(file, join(["swarm"; flags; swarmname], " "))
    end
end

function make_swarm(;jobids = collect(1:12000), sims_per_subj = 20, nboot = 1000, jobname = "illnessdeath_sim.jl", swarmname = "illnessdeath.swarm", callname = "runswarm.txt", filepath = "sim1_illnessdeath/slurm_scripts/")
    
    # alias the functions to make the swarm call and job
    make_swarmcall(swarmname, filepath * callname, jobids);

    make_jobs(jobids, sims_per_subj, nboot, jobname, filepath * swarmname);
end
