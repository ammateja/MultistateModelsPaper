#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-04:00:00
#SBATCH --ntasks=1
#SBATCH --mem=50g
#SBATCH --gres=lscratch:5
#=
module load julia
srun julia $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using DataFrames
include("swarm_helpers.jl")

# to make missing jobs
function make_missing_jobs(; sims, boots, model_numbers, nulleffs, filename = "/data/fintzijr/multistate/sim2_regen/regen_sim_results_")
    
    # enumerate jobs
    jobs = reduce(vcat, [[s1 s2 y z] for s1 in sims for s2 in boots for y in model_numbers for z in nulleffs])
    jobs = jobs[Not((jobs[:,3] .∈ Ref([1,2])) .& (jobs[:,2] .!= 0)),:]

    # filenames
    filenames = filename .*  map(x->join(x, "."), eachrow(string.(jobs))) .* ".bson"

    # check if exists
    exists = [isfile(x) for x in filenames]

    # remove existing files
    jobs = jobs[Not(exists), :]

    ### make the swamrms
    # full 1
    if any(jobs[:,3] .== 1)
        if isfile("runswarm_full1.txt")
            rm("runswarm_full1.txt")
        end
        
        flags = join(
        ["--module julia",
        "--noht",# no hyperthreading (tasks per core = 1)
        "--merge-output",
        "--logdir ./swarmlogs",
        # "-t 2", # allocate node exclusively
        "-g 32", # mem per task
        "--time-per-subjob=00-04:00:00",
        "--partition=quick", 
        raw"--sbatch '--constraint=ibhdr100'"]," ")
    
        # write swarmcall
        open("runswarm_full1.txt", "a") do file
            write(file, join(["swarm"; flags; "regen_sim_full1.swarm"], " "))
        end
        
        # swarn
        if isfile("runswarm_full1.txt")
            rm("runswarm_full1.txt")
        end
                
        jobs1 = jobs[findall(jobs[:,3] .== 1), :]
        calls = "julia regen_sim.jl " .* map(x -> join(x, " "), eachrow(jobs1)) .* "\n"

        open("regen_sim_full1.swarm", "a") do file
            for c in calls
                write(file, c)
            end
        end
    end

    # full 2
    if any(jobs[:,3] .== 2)
        if isfile("runswarm_full2.txt")
            rm("runswarm_full2.txt")
        end
        
        flags = join(
        ["--module julia",
        "--noht",# no hyperthreading (tasks per core = 1)
        "--merge-output",
        "--logdir ./swarmlogs",
        # "-t 2", # allocate node exclusively
        "-g 32", # mem per task
        "--time-per-subjob=10-00:00:00",
        "--partition=norm", 
        raw"--sbatch '--constraint=ibhdr100'"]," ")
    
        # write swarmcall
        open("runswarm_full2.txt", "a") do file
            write(file, join(["swarm"; flags; "regen_sim_full2.swarm"], " "))
        end
        
        # swarn
        if isfile("runswarm_full2.txt")
            rm("runswarm_full2.txt")
        end
                
        jobs2 = jobs[findall(jobs[:,3] .== 2), :]
        calls = "julia regen_sim.jl " .* map(x -> join(x, " "), eachrow(jobs2)) .* "\n"

        open("regen_sim_full2.swarm", "a") do file
            for c in calls
                write(file, c)
            end
        end
    end

    if any(jobs[:,3] .∈ Ref([3,4]))
        if isfile("runswarm_collapsed.txt")
            rm("runswarm_collapsed.txt")
        end
        
        flags = join(
        ["--module julia",
        "--noht",# no hyperthreading (tasks per core = 1)
        "--merge-output",
        "--logdir ./swarmlogs",
        # "-t 2", # allocate node exclusively
        "-g 8", # mem per task
        "--time-per-subjob=00-04:00:00",
        "--partition=norm,quick", 
        raw"--sbatch '--constraint=ibhdr100'"]," ")
    
        # write swarmcall
        open("runswarm_collapsed.txt", "a") do file
            write(file, join(["swarm"; flags; "regen_sim_collapsed.swarm"], " "))
        end
        
        # swarm
        if isfile("regen_sim_collapsed.swarm")
            rm("regen_sim_collapsed.swarm")
        end
                
        jobsc = jobs[findall(jobs[:,3] .∈ Ref([3,4])), :]
        calls = "julia regen_sim.jl " .* map(x -> join(x, " "), eachrow(jobsc)) .* "\n"

        open("regen_sim_collapsed.swarm", "a") do file
            for c in calls
                write(file, c)
            end
        end

        # split into 4 swarm arrays
        # arrayinds = (collect(1:length(calls) .- 1) .% 4) .+ 1

        # open("regen_sim_collapsed1.swarm", "a") do file
        #     for c in calls[findall(arrayinds .== 1)]
        #         write(file, c)
        #     end
        # end

        # open("regen_sim_collapsed2.swarm", "a") do file
        #     for c in calls[findall(arrayinds .== 2)]
        #         write(file, c)
        #     end
        # end

        # open("regen_sim_collapsed3.swarm", "a") do file
        #     for c in calls[findall(arrayinds .== 3)]
        #         write(file, c)
        #     end
        # end

        # open("regen_sim_collapsed4.swarm", "a") do file
        #     for c in calls[findall(arrayinds .== 4)]
        #         write(file, c)
        #     end
        # end
    end   
end

make_missing_jobs(; sims = 1:1000, boots = 0:1000, model_numbers = 3:4, nulleffs = 1)