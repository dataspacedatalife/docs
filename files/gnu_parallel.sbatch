#!/bin/bash
#SBATCH --job-name=gnu-parallel
#SBATCH --partition=cpu-best-amd
#SBATCH --nodes=1
#SBATCH --ntasks=192
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm-%x-%j.out
#SBATCH --error=logs/slurm-%x-%j.err

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"

mkdir -p logs

parallel \
	--delay 0.01 \
	--jobs $SLURM_NTASKS \
	--joblog logs/runtask.log \
	--resume-failed \
	"srun --exclusive --nodes=1 --ntasks=1 --cpus-per-task=${OMP_NUM_THREADS:-1} \
	./task.sh {1} > logs/parallel_{1}.log 2>&1" \
	::: {0..191}
