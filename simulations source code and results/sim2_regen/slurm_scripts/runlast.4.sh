#!/bin/bash
#SBATCH --partition=quick
#SBATCH --time=00-00:01:00
#SBATCH --ntasks=1
#SBATCH --mem=1g
#SBATCH --gres=lscratch:5
#SBATCH --wait --dependency 23388761

swarm --module julia --noht --merge-output --logdir ./swarmlogs -g 8 --time-per-subjob=10-00:00:00 --partition=norm --sbatch '--constraint=ibhdr100' regen_sim_collapsed_751.1000.4.1.swarm