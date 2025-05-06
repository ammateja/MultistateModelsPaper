#!/usr/bin/env sh
#SBATCH --partition=quick
#SBATCH --time=00-04:00:00
#SBATCH --ntasks=1
#SBATCH --mem=25g
#SBATCH --gres=lscratch:5
#=
module load julia
srun julia $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using BSON
using CSV
using DataFrames

# files1 = ["/data/fintzijr/multistate/sim2_regen/regen_sim_results_$k.0.1.1.bson" for k in 1:1000]
files2 = ["/data/fintzijr/multistate/sim2_regen/regen_sim_results_$k.0.2.1.bson" for k in 1:1000]
files3 = ["/data/fintzijr/multistate/sim2_regen/regen_sim_results_$k.$b.3.1.bson" for k in 1:1000 for b in 0:200]
files4 = ["/data/fintzijr/multistate/sim2_regen/regen_sim_results_$k.$b.4.1.bson" for k in 1:1000 for b in 0:200]

# res1 = mapreduce(x -> BSON.load(x)[:results], vcat, files1)
res2 = mapreduce(x -> BSON.load(x)[:results], vcat, files2)
res3 = mapreduce(x -> BSON.load(x)[:results], vcat, files3)
res4 = mapreduce(x -> BSON.load(x)[:results], vcat, files4)

# make vector
# res1.ests = reduce(vcat, res1.ests)
res2.ests = reduce(vcat, res2.ests)

# write csv
# CSV.write("/home/fintzijr/multistate/sim2_regen/regensim_results_1.csv", res1)
CSV.write("/home/fintzijr/multistate/sim2_regen/regensim_results_2.csv", res2)
CSV.write("/home/fintzijr/multistate/sim2_regen/regensim_results_3.csv", res3)
CSV.write("/home/fintzijr/multistate/sim2_regen/regensim_results_4.csv", res4)