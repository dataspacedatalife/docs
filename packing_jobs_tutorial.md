# Packing Small Jobs on OHDS

## Purpose

This guide shows how to run many small, independent jobs inside one larger SLURM job using GNU Parallel.

This is very useful when you have several jobs that do not use one whole node so several of them can be merged in a larger job to make good use of all the node resources.

The example uses:

* [gnu_parallel.sbatch](files/gnu_parallel.sbatch), a SLURM submission script.
* [task.sh](files/task.sh), a small task script called once for each task ID.

## When to use this pattern

Use this approach for workloads where:

* Each task is independent.
* Each task uses one CPU core, or a small fixed number of CPU cores.
* Tasks are short or moderately short.
* Tasks can be identified by an index, filename, sample ID, or parameter value.
* Failed tasks can be rerun safely.

Do not use this template for tightly coupled MPI jobs, very large memory jobs, or tasks that must communicate with each other while running.

## Quick start

1. Copy the example files to your working directory:

   ```bash
   cp files/gnu_parallel.sbatch .
   cp files/task.sh .
   ```

2. Make sure the task script is executable:

   ```bash
   chmod +x task.sh
   ```

3. Edit `task.sh` so that it runs your task.

   The example task receives one argument in a similar way to a SLURM array job:

   ```bash
   ./task.sh 0
   ```

4. Edit `gnu_parallel.sbatch` if you need to adjust the time limit of the job:

   ```bash
   #SBATCH --time=01:00:00
   ```

5. Submit the job:

   ```bash
   sbatch gnu_parallel.sbatch
   ```

6. Check the logs:

   ```bash
   ls logs
   tail logs/slurm-gnu-parallel-*.out
   less logs/runtask.log
   ```

## Adapting the task list

For 192 numbered tasks:

```bash
::: {0..191}
```

For 1000 numbered tasks:

```bash
::: {0..999}
```

For a list of input files:

```bash
::: inputs/*.txt
```

Then `task.sh` can use the first argument as the input file:

```bash
#!/bin/bash
input="$1"

my_program "$input"
```

GNU Parallel may run more total tasks than allocated cores. For example, with `--ntasks=192` and `::: {0..999}`, it runs at most 192 tasks at a time and starts new tasks as old ones finish.

## Choosing the job size

Set `--ntasks` to the number of tasks you want to run at the same time.

For one-core tasks on a 192-core node:

```bash
#SBATCH --nodes=1
#SBATCH --ntasks=192
#SBATCH --cpus-per-task=1
```

For tasks that need 4 CPU threads each, use fewer simultaneous tasks:

```bash
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --cpus-per-task=4
```

## Output files

The example creates a `logs` directory.

Main SLURM logs:

```text
logs/slurm-gnu-parallel-JOBID.out
logs/slurm-gnu-parallel-JOBID.err
```

Per-task logs:

```text
logs/parallel_0.log
logs/parallel_1.log
logs/parallel_2.log
...
```

GNU Parallel joblog:

```text
logs/runtask.log
```

The joblog is the best place to check which tasks succeeded or failed. A successful task has exit value `0`.

## Rerunning failed tasks

The example includes:

```bash
--resume-failed
```

If the job is submitted again from the same directory and `logs/runtask.log` still exists, GNU Parallel uses the joblog to skip completed tasks and rerun failed or unfinished tasks.

If you want to rerun everything from scratch, remove the old logs first:

```bash
rm -r logs
```
