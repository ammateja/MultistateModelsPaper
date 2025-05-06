#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-00:05:00
#SBATCH --ntasks=1
#SBATCH --mem=1g
#SBATCH --gres=lscratch:5
#=
module load julia
srun julia $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using DataFrames

function make_jobs(; jobids = string.(collect(1:8000)), sims_per_subj = 20, nboot = 1000, filename = "/data/fintzijr/multistate/sim1_illnessdeath/illnessdeath_results_", swarmname = "/home/fintzijr/multistate/sim1_illnessdeath/illnessdeath.swarm", jobname = "illnessdeath_sim.jl")
    
    # remove the existing file
    if isfile(swarmname)
        rm(swarmname)
    end

    # find missing results
    filenames = fill(filename, length(jobids)) .* jobids .* fill(".bson", length(jobids))
    jobids = parse.(Int64, jobids[.!isfile.(filenames)])

    # jobgrid
    jobgrid = DataFrame(family = [1,2,3])

    # write jobs to swarm file
    touch(swarmname)
    open(swarmname, "a") do file
        for j in jobids
            # index into job grid
            family = Int64(ceil(j/1000))
            
            # get seed, censoring value, and treatment effect value
            seed = Int64(mod(j - 1, 1000) + 1)

            # append to file
            open(swarmname, "a") do file
                write(file, join(["julia"; jobname; "$j"; "$seed"; "$family"; "$sims_per_subj"; "$nboot"; "\n"], " "))
            end
        end
    end      
end

make_jobs()