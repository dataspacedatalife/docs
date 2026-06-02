# Running GROMACS on CPU and GPU Resources

This tutorial explains how to run a basic GROMACS molecular dynamics test case on CPU and GPU resources. It includes examples for:
---
- Interactive execution
- CPU runs
- GPU runs
- SLURM job submission
- AWS EC2 execution
- Multi-GPU and multi-node runs
- Benchmarking and troubleshooting

The tutorial is designed to be used as a GitHub `README.md` file for training users, testing GROMACS installations, or validating CPU/GPU resources on HPC systems.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Required Files](#2-required-files)
3. [Directory Structure](#3-directory-structure)
4. [Loading GROMACS](#4-loading-gromacs)
5. [Preparing the Test Case](#5-preparing-the-test-case)
6. [Interactive GROMACS Runs](#6-interactive-gromacs-runs)
7. [CPU Launch Script](#7-cpu-launch-script)
8. [GPU Launch Script](#8-gpu-launch-script)
9. [SLURM CPU Job Script](#9-slurm-cpu-job-script)
10. [SLURM GPU Job Script](#10-slurm-gpu-job-script)
11. [SLURM GPU Job with Explicit GPU Offload](#11-slurm-gpu-job-with-explicit-gpu-offload)
12. [MPI versus Thread-MPI Builds](#12-mpi-versus-thread-mpi-builds)
13. [Multi-GPU Single-Node Runs](#13-multi-gpu-single-node-runs)
14. [Multi-Node CPU Runs](#14-multi-node-cpu-runs)
15. [Multi-Node GPU Runs](#15-multi-node-gpu-runs)
16. [Running GROMACS on AWS EC2](#16-running-gromacs-on-aws-ec2)
17. [Recommended AWS Directory Layout](#17-recommended-aws-directory-layout)
18. [Monitoring a Run](#18-monitoring-a-run)
19. [Checking Performance](#19-checking-performance)
20. [Suggested Benchmark Matrix](#20-suggested-benchmark-matrix)
21. [Common Problems and Fixes](#21-common-problems-and-fixes)
22. [Restarting from a Checkpoint](#22-restarting-from-a-checkpoint)
23. [Recommended Production-Style Commands](#23-recommended-production-style-commands)
24. [Final CPU and GPU Scripts](#24-final-cpu-and-gpu-scripts)
25. [Final Checklist](#25-final-checklist)
26. [Practical Recommendations](#26-practical-recommendations)

---

## 1. Introduction

GROMACS is a widely used molecular dynamics package for simulating biomolecular and non-biomolecular systems, including proteins, lipids, membranes, polymers, solvents, and ion channels.

The main command used to launch molecular dynamics simulations is:

```bash
gmx mdrun
```

or, when using an MPI-enabled GROMACS build:

```bash
gmx_mpi mdrun
```

The `mdrun` program reads a binary GROMACS input file, usually with extension `.tpr`, and performs the molecular dynamics simulation.

A typical command looks like this:

```bash
gmx mdrun -s ion_channel.tpr
```

where:

- `gmx` is the GROMACS command-line executable.
- `mdrun` is the GROMACS molecular dynamics engine.
- `-s ion_channel.tpr` specifies the binary input file.

This tutorial uses a short ion-channel benchmark/test case to illustrate how to run GROMACS on CPU and GPU resources.

---

## 2. Required Files

The example uses the following files:

```text
GROMACS_TestCaseA.tar.gz
ion_channel.tpr
run-cpu.sh
run-gpu.sh
```

The most important file is:

```text
ion_channel.tpr
```

The `.tpr` file is a compiled GROMACS input file. It contains all the information needed by `mdrun`, including:

- Molecular system
- Topology
- Force-field parameters
- Simulation parameters
- Initial coordinates
- Velocities, if present
- Constraints and integration settings

If `ion_channel.tpr` is not already available, it can be extracted from:

```text
GROMACS_TestCaseA.tar.gz
```

The provided launch scripts run a short benchmark-style simulation using:

```bash
time gmx mdrun -s ion_channel.tpr -maxh 0.50 -resethway -noconfout -nsteps 10000 -g logfile
```


This command runs 10,000 MD steps and writes the GROMACS log to:

```text
logfile.log
```

---

## 3. Directory Structure

A clean working directory should look like this:

```text
gromacs-test/
├── GROMACS_TestCaseA.tar.gz
├── ion_channel.tpr
├── run-cpu.sh
└── run-gpu.sh
```

On a cluster, it is usually better to work in a scratch or project directory:

```bash
mkdir -p /scratch/$USER/gromacs-test
cd /scratch/$USER/gromacs-test
```

or:

```bash
mkdir -p $HOME/gromacs-test
cd $HOME/gromacs-test
```

On AWS, using a dedicated data volume is recommended:

```bash
sudo mkdir -p /data/gromacs-test
sudo chown -R $USER:$USER /data/gromacs-test
cd /data/gromacs-test
```

---

## 4. Loading GROMACS

The exact command depends on the system where GROMACS is installed.

### 4.1. Using Environment Modules

On many HPC systems, GROMACS is provided through environment modules.

List available versions:

```bash
module avail GROMACS
```

Load a default version:

```bash
module purge
module load GROMACS
```

Or load a specific version:

```bash
module purge
module load GROMACS/2025.4
```

Check that GROMACS is available:

```bash
gmx --version
```

You should see information such as:

```text
GROMACS version:    2025.x
GPU support:        CUDA
MPI library:        thread_mpi or external MPI
```

For GPU jobs on NVIDIA hardware, make sure the installed GROMACS build has CUDA support.

---

### 4.2. Using EESSI

If the system uses EESSI, one possible setup is:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module avail GROMACS
module load GROMACS/2025.4-foss-2025b
```

Then verify:

```bash
gmx --version
```

---

### 4.3. Using a Container

If GROMACS is provided through Apptainer/Singularity:

```bash
apptainer exec gromacs.sif gmx --version
```

A CPU run would look like:

```bash
apptainer exec gromacs.sif gmx mdrun -s ion_channel.tpr -nsteps 10000
```

A GPU run on NVIDIA hardware usually requires `--nv`:

```bash
apptainer exec --nv gromacs.sif gmx mdrun -s ion_channel.tpr -nsteps 10000 -nb gpu
```

---

## 5. Preparing the Test Case

If `ion_channel.tpr` is already present, no preparation is required.

Check:

```bash
ls -lh ion_channel.tpr
```

If only the compressed file is present, extract it:

```bash
tar xfz GROMACS_TestCaseA.tar.gz
```

Check again:

```bash
ls -lh ion_channel.tpr
```

Expected result:

```text
ion_channel.tpr
```

---

## 6. Interactive GROMACS Runs

Interactive runs are useful for quick tests, debugging, or checking that GROMACS and the hardware are working correctly.

### 6.1. Basic CPU Test

```bash
gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile
```

This produces output files such as:

```text
logfile.log
ener.edr
state.cpt
```

Depending on the options and defaults, GROMACS may also produce trajectory-related files.

---

### 6.2. Basic GPU Test

For a GPU-enabled GROMACS build:

```bash
gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -nb gpu
```

The option:

```bash
-nb gpu
```

requests GPU offload for non-bonded calculations.

For many recent GROMACS versions, GPU detection is automatic, but it is useful to be explicit when benchmarking or validating GPU resources.

---

### 6.3. More Aggressive GPU Offload

Depending on the GROMACS version, GPU backend, hardware, and simulation setup, you may test:

```bash
gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -nb gpu \
    -pme gpu \
    -bonded gpu \
    -update gpu
```

However, not every system or GROMACS build supports all GPU offload modes. If the run fails, reduce the offload level:

```bash
gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -nb gpu
```

A safe first GPU test is:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -nb gpu
```

Then progressively test additional offload options.

---

## 7. CPU Launch Script

Create a file called:

```text
run-cpu.sh
```

with the following content:

```bash
#!/bin/bash
set -euo pipefail

echo "Starting GROMACS CPU test"
echo "Working directory: $(pwd)"
echo "Hostname: $(hostname)"
echo "Date: $(date)"

# Load GROMACS.
# Adapt this line to your system.
module purge
module load GROMACS/2025.4-foss-2025b

echo "GROMACS version:"
gmx --version

# Prepare input file if needed.
if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
    echo "GROMACS_TestCaseA.tar.gz not found. Downloading test case..."
    curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "ion_channel.tpr not found. Extracting archive..."
    tar xfz GROMACS_TestCaseA.tar.gz
fi

# Clean previous outputs.
rm -f ener.edr logfile.log state.cpt md.log

# Recommended CPU threading variable.
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}

echo "Running with OMP_NUM_THREADS=${OMP_NUM_THREADS}"

time gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}"

echo "GROMACS CPU test finished"
echo "Date: $(date)"
```

Make it executable:

```bash
chmod +x run-cpu.sh
```

Run it:

```bash
./run-cpu.sh
```

---

## 8. GPU Launch Script

Create a file called:

```text
run-gpu.sh
```

with the following content:

```bash
#!/bin/bash
set -euo pipefail

echo "Starting GROMACS GPU test"
echo "Working directory: $(pwd)"
echo "Hostname: $(hostname)"
echo "Date: $(date)"

# Load GROMACS.
# Adapt this line to your system.
module purge
module load GROMACS/2025.4-foss-2025b

echo "GROMACS version:"
gmx --version

echo "GPU information:"
nvidia-smi || true

# Prepare input file if needed.
if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
    echo "GROMACS_TestCaseA.tar.gz not found. Downloading test case..."
    curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "ion_channel.tpr not found. Extracting archive..."
    tar xfz GROMACS_TestCaseA.tar.gz
fi

# Clean previous outputs.
rm -f ener.edr logfile.log state.cpt md.log

# Select GPU 0 by default.
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}

# CPU threads used to feed the GPU.
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}

echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES}"
echo "OMP_NUM_THREADS=${OMP_NUM_THREADS}"

time gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu

echo "GROMACS GPU test finished"
echo "Date: $(date)"
```

Make it executable:

```bash
chmod +x run-gpu.sh
```

Run it:

```bash
./run-gpu.sh
```

---

## 9. SLURM CPU Job Script

For an HPC system using SLURM, create:

```text
submit-gromacs-cpu.slurm
```

```bash
#!/bin/bash
#SBATCH --job-name=gmx-cpu-test
#SBATCH --output=gmx-cpu-%j.out
#SBATCH --error=gmx-cpu-%j.err
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=00:30:00
#SBATCH --mem=8G

set -euo pipefail

echo "Job ID: ${SLURM_JOB_ID}"
echo "Node list: ${SLURM_JOB_NODELIST}"
echo "Working directory: $(pwd)"
echo "Date: $(date)"

module purge
module load GROMACS/2025.4-foss-2025b

gmx --version

if [ ! -f ion_channel.tpr ]; then
    if [ -f GROMACS_TestCaseA.tar.gz ]; then
        tar xfz GROMACS_TestCaseA.tar.gz
    else
        curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
        tar xfz GROMACS_TestCaseA.tar.gz
    fi
fi

rm -f ener.edr logfile.log state.cpt

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

srun gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}"

echo "Finished at: $(date)"
```

Submit with:

```bash
sbatch submit-gromacs-cpu.slurm
```

Check the queue:

```bash
squeue -u $USER
```

Inspect output:

```bash
tail -f gmx-cpu-<jobid>.out
```

---

## 10. SLURM GPU Job Script

Create:

```text
submit-gromacs-gpu.slurm
```

```bash
#!/bin/bash
#SBATCH --job-name=gmx-gpu-test
#SBATCH --output=gmx-gpu-%j.out
#SBATCH --error=gmx-gpu-%j.err
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --mem=16G

set -euo pipefail

echo "Job ID: ${SLURM_JOB_ID}"
echo "Node list: ${SLURM_JOB_NODELIST}"
echo "Working directory: $(pwd)"
echo "Date: $(date)"

module purge
module load GROMACS/2025.4-foss-2025b

gmx --version

echo "GPU status before run:"
nvidia-smi || true

if [ ! -f ion_channel.tpr ]; then
    if [ -f GROMACS_TestCaseA.tar.gz ]; then
        tar xfz GROMACS_TestCaseA.tar.gz
    else
        curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
        tar xfz GROMACS_TestCaseA.tar.gz
    fi
fi

rm -f ener.edr logfile.log state.cpt

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

srun gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu

echo "GPU status after run:"
nvidia-smi || true

echo "Finished at: $(date)"
```

Submit with:

```bash
sbatch submit-gromacs-gpu.slurm
```

---

## 11. SLURM GPU Job with Explicit GPU Offload

For more complete GPU offload, test this variant:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-gpu-full
#SBATCH --output=gmx-gpu-full-%j.out
#SBATCH --error=gmx-gpu-full-%j.err
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --mem=16G

set -euo pipefail

module purge
module load GROMACS/2025.4-foss-2025b

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

nvidia-smi
gmx --version

if [ ! -f ion_channel.tpr ]; then
    tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log state.cpt

srun gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu \
    -pme gpu \
    -bonded gpu \
    -update gpu
```

If this fails, try removing `-update gpu` first:

```bash
-pme gpu -bonded gpu
```

If it still fails, use only:

```bash
-nb gpu
```

This progressive approach is safer because not all simulations and builds support all GPU offload paths.

---

## 12. MPI versus Thread-MPI Builds

There are two common ways to run GROMACS:

1. Non-MPI or thread-MPI build
2. External MPI build

### 12.1. Non-MPI or Thread-MPI Build

Command:

```bash
gmx mdrun
```

Typical single-node CPU command:

```bash
gmx mdrun -s ion_channel.tpr -ntomp 16
```

Typical single-node GPU command:

```bash
gmx mdrun -s ion_channel.tpr -ntomp 8 -nb gpu
```

---

### 12.2. External MPI Build

Command:

```bash
gmx_mpi mdrun
```

Typical single-node MPI command:

```bash
srun gmx_mpi mdrun -s ion_channel.tpr -ntomp 4
```

For example, with 4 MPI ranks and 4 OpenMP threads per rank:

```bash
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=4

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

srun gmx_mpi mdrun \
    -s ion_channel.tpr \
    -ntomp ${OMP_NUM_THREADS}
```

Total CPU cores used:

```text
ntasks × cpus-per-task = 4 × 4 = 16 CPU cores
```

---

## 13. Multi-GPU Single-Node Runs

For a node with 4 GPUs, a common starting point is one MPI rank per GPU.

Example SLURM script:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-4gpu
#SBATCH --output=gmx-4gpu-%j.out
#SBATCH --error=gmx-4gpu-%j.err
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:4
#SBATCH --time=01:00:00
#SBATCH --mem=64G

set -euo pipefail

module purge
module load GROMACS/2025.4-foss-2025b

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

nvidia-smi
gmx_mpi --version || gmx --version

if [ ! -f ion_channel.tpr ]; then
    tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log state.cpt

srun gmx_mpi mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu \
    -pme gpu
```

Depending on the installation, the executable may be `gmx` rather than `gmx_mpi`.

Check with:

```bash
which gmx
which gmx_mpi
```

---

## 14. Multi-Node CPU Runs

For larger CPU-only jobs:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-cpu-multinode
#SBATCH --output=gmx-cpu-multinode-%j.out
#SBATCH --error=gmx-cpu-multinode-%j.err
#SBATCH --partition=cpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=4
#SBATCH --time=02:00:00
#SBATCH --mem=0

set -euo pipefail

module purge
module load GROMACS/2025.4-foss-2025b

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

if [ ! -f ion_channel.tpr ]; then
    tar xfz GROMACS_TestCaseA.tar.gz
fi

srun gmx_mpi mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}"
```

Here:

```text
2 nodes × 8 MPI ranks per node × 4 OpenMP threads = 64 CPU cores
```

---

## 15. Multi-Node GPU Runs

For a system with 4 GPUs per node and 2 nodes:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-gpu-multinode
#SBATCH --output=gmx-gpu-multinode-%j.out
#SBATCH --error=gmx-gpu-multinode-%j.err
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:4
#SBATCH --time=02:00:00
#SBATCH --mem=0

set -euo pipefail

module purge
module load GROMACS/2025.4-foss-2025b

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

if [ ! -f ion_channel.tpr ]; then
    tar xfz GROMACS_TestCaseA.tar.gz
fi

srun gmx_mpi mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu \
    -pme gpu
```

This requests:

```text
2 nodes × 4 GPUs per node = 8 GPUs
2 nodes × 4 MPI ranks per node = 8 MPI ranks
```

That gives one MPI rank per GPU.

For small systems, multi-node GPU scaling may be inefficient because communication overhead can dominate. Always benchmark.

---

## 16. Running GROMACS on AWS EC2

On a plain AWS EC2 instance without SLURM, use a normal shell script.

For a GPU instance, first check:

```bash
nvidia-smi
```

Then check GROMACS:

```bash
gmx --version
```

A simple AWS GPU script could be:

```bash
#!/bin/bash
set -euo pipefail

cd /data/gromacs-test

source /etc/profile || true

# Load module if available.
# module load GROMACS/2025.4-foss-2025b

nvidia-smi
gmx --version

if [ ! -f ion_channel.tpr ]; then
    tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log state.cpt

export CUDA_VISIBLE_DEVICES=0
export OMP_NUM_THREADS=8

time gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu
```

Save it as:

```text
run-aws-gpu.sh
```

Then:

```bash
chmod +x run-aws-gpu.sh
./run-aws-gpu.sh
```

---

## 17. Recommended AWS Directory Layout

Use an EBS volume or local NVMe disk mounted under `/data`:

```text
/data/gromacs-test/
├── GROMACS_TestCaseA.tar.gz
├── ion_channel.tpr
├── run-aws-cpu.sh
├── run-aws-gpu.sh
├── outputs/
└── logs/
```

Create it:

```bash
sudo mkdir -p /data/gromacs-test
sudo chown -R $USER:$USER /data/gromacs-test
cd /data/gromacs-test
```

Copy files with `rsync`:

```bash
rsync -avP -e "ssh -i my-key.pem" \
    GROMACS_TestCaseA.tar.gz ion_channel.tpr run-gpu.sh run-cpu.sh \
    ubuntu@<PUBLIC_IP>:/data/gromacs-test/
```

For large files, use:

```bash
rsync -avP --partial --append-verify -e "ssh -i my-key.pem" \
    GROMACS_TestCaseA.tar.gz ion_channel.tpr \
    ubuntu@<PUBLIC_IP>:/data/gromacs-test/
```

---

## 18. Monitoring a Run

### 18.1. Check Job Status in SLURM

```bash
squeue -u $USER
```

Detailed information:

```bash
scontrol show job <jobid>
```

Cancel a job:

```bash
scancel <jobid>
```

---

### 18.2. Follow the GROMACS Log

```bash
tail -f logfile.log
```

For SLURM output:

```bash
tail -f gmx-gpu-<jobid>.out
```

---

### 18.3. Monitor GPU Usage

On the compute node:

```bash
nvidia-smi
```

Continuous monitoring:

```bash
watch -n 1 nvidia-smi
```

Useful indicators:

- GPU utilization close to 80–100% usually means good GPU use.
- Very low GPU utilization may indicate too few CPU threads, too small a system, bad CPU/GPU balance, or insufficient offload.
- High CPU usage with low GPU usage may indicate that the CPU is the bottleneck.
- High GPU memory use is normal, but out-of-memory errors require reducing the workload or using a GPU with more memory.

---

## 19. Checking Performance

At the end of `logfile.log`, GROMACS prints a performance summary. Look for lines similar to:

```text
Performance:      XXX ns/day
```

To extract this quickly:

```bash
grep -i "Performance" logfile.log
```

or:

```bash
tail -n 100 logfile.log
```

Compare different runs by changing:

```text
-ntomp
-ntmpi
-nt
-nb gpu
-pme gpu
-bonded gpu
-update gpu
```

For benchmarking, keep the same input file and number of steps.

---

## 20. Suggested Benchmark Matrix

For a single GPU node, test:

```text
Run 1: CPU only, 8 threads
Run 2: CPU only, 16 threads
Run 3: GPU, -nb gpu, 4 CPU threads
Run 4: GPU, -nb gpu, 8 CPU threads
Run 5: GPU, -nb gpu -pme gpu, 8 CPU threads
Run 6: GPU, -nb gpu -pme gpu -bonded gpu, 8 CPU threads
Run 7: GPU, -nb gpu -pme gpu -bonded gpu -update gpu, 8 CPU threads
```

Example:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -ntomp 8 -nb gpu
```

Then:

```bash
grep -i "Performance" logfile.log
mv logfile.log logfile_gpu_nb_ntomp8.log
```

---

## 21. Common Problems and Fixes

### Problem 1: `gmx: command not found`

Cause: GROMACS is not loaded.

Fix:

```bash
module avail GROMACS
module load GROMACS/2025.4-foss-2025b
```

or use the full path:

```bash
/path/to/gromacs/bin/gmx --version
```

---

### Problem 2: `ion_channel.tpr: No such file or directory`

Cause: the `.tpr` file is missing.

Fix:

```bash
tar xfz GROMACS_TestCaseA.tar.gz
ls -lh ion_channel.tpr
```

---

### Problem 3: GPU Requested but Not Used

Check whether GROMACS was compiled with GPU support:

```bash
gmx --version | grep -i -E "GPU|CUDA|SYCL|HIP"
```

Check whether the GPU is visible:

```bash
nvidia-smi
```

Run with explicit GPU offload:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -nb gpu
```

You can also select a GPU using:

```bash
export CUDA_VISIBLE_DEVICES=0
```

or, depending on the build and version:

```bash
export GMX_GPU_ID=0
```

---

### Problem 4: CUDA Out of Memory

Symptoms:

```text
CUDA error
out of memory
```

Possible fixes:

- Use a GPU with more memory.
- Reduce system size.
- Avoid running multiple jobs on the same GPU.
- Check that no other processes are using the GPU:

```bash
nvidia-smi
```

---

### Problem 5: Poor GPU Performance

Possible causes:

- Too few CPU threads feeding the GPU.
- Too many CPU threads causing overhead.
- System too small for the GPU.
- PME still running on CPU.
- Bad MPI/OpenMP layout.
- Multiple jobs sharing the same GPU.
- Slow filesystem.

Try:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -ntomp 8 -nb gpu
```

Then:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -ntomp 8 -nb gpu -pme gpu
```

Compare `ns/day`.

---

### Problem 6: SLURM Says GPU Is Unavailable

Check the correct partition name:

```bash
sinfo
```

Check GPU resources:

```bash
sinfo -o "%P %N %G"
```

Your cluster may use:

```bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
```

or:

```bash
#SBATCH --partition=a100
#SBATCH --gres=gpu:a100:1
```

or:

```bash
#SBATCH --partition=g6e
#SBATCH --gres=gpu:1
```

Use the format required by your cluster.

---

### Problem 7: Run Stops Because of `-maxh`

The option:

```bash
-maxh 0.50
```

limits the run to approximately half an hour.

For production runs, increase it:

```bash
-maxh 23.5
```

or remove it entirely if the walltime is controlled by SLURM.

In SLURM, the main walltime is controlled by:

```bash
#SBATCH --time=24:00:00
```

A useful production pattern is to set `-maxh` slightly lower than the SLURM walltime so that GROMACS writes a checkpoint before the scheduler kills the job:

```bash
#SBATCH --time=24:00:00

gmx mdrun -s topol.tpr -deffnm md -maxh 23.5
```

---

## 22. Restarting from a Checkpoint

GROMACS writes checkpoint files such as:

```text
state.cpt
```

To continue a run:

```bash
gmx mdrun \
    -s ion_channel.tpr \
    -cpi state.cpt \
    -append
```

A more common production command is:

```bash
gmx mdrun \
    -deffnm md \
    -cpi md.cpt \
    -append
```

where `-deffnm md` means that GROMACS will use files such as:

```text
md.tpr
md.log
md.edr
md.xtc
md.cpt
```

---

## 23. Recommended Production-Style Commands

For a production run, it is usually cleaner to use:

```bash
gmx mdrun -deffnm md
```

instead of manually specifying each file.

Example:

```bash
gmx mdrun \
    -deffnm md \
    -cpi md.cpt \
    -append \
    -maxh 23.5
```

For GPU:

```bash
gmx mdrun \
    -deffnm md \
    -cpi md.cpt \
    -append \
    -maxh 23.5 \
    -nb gpu \
    -pme gpu
```

---

## 24. Final CPU and GPU Scripts

### 24.1. Final CPU Script

```bash
#!/bin/bash
set -euo pipefail

module purge
module load GROMACS/2025.4-foss-2025b

if [ ! -f ion_channel.tpr ]; then
    tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log state.cpt

export OMP_NUM_THREADS=${OMP_NUM_THREADS:-16}

time gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp ${OMP_NUM_THREADS}
```

---

### 24.2. Final GPU Script

```bash
#!/bin/bash
set -euo pipefail

module purge
module load GROMACS/2025.4-foss-2025b

nvidia-smi

if [ ! -f ion_channel.tpr ]; then
    tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log state.cpt

export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}

time gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp ${OMP_NUM_THREADS} \
    -nb gpu
```

---

## 25. Final Checklist

Before running:

```bash
gmx --version
```

Check GPU availability:

```bash
nvidia-smi
```

Check input file:

```bash
ls -lh ion_channel.tpr
```

Run CPU test:

```bash
./run-cpu.sh
```

Run GPU test:

```bash
./run-gpu.sh
```

Submit CPU SLURM job:

```bash
sbatch submit-gromacs-cpu.slurm
```

Submit GPU SLURM job:

```bash
sbatch submit-gromacs-gpu.slurm
```

Check performance:

```bash
grep -i "Performance" logfile.log
```

Check errors:

```bash
grep -i "error\|fatal\|warning" logfile.log
```

---

## 26. Practical Recommendations

For this specific test case:

1. Start with the simple CPU run.
2. Then run GPU with only:

```bash
-nb gpu
```

3. Compare `ns/day` in `logfile.log`.
4. Then test:

```bash
-nb gpu -pme gpu
```

5. Only after that test:

```bash
-nb gpu -pme gpu -bonded gpu -update gpu
```

6. Keep the best-performing combination for the target hardware.

The safest default GPU command for initial testing is:

```bash
gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp 8 \
    -nb gpu
```

For production, use checkpointing and a `-maxh` value slightly below the SLURM walltime:

```bash
gmx mdrun \
    -deffnm md \
    -cpi md.cpt \
    -append \
    -maxh 23.5 \
    -nb gpu \
    -pme gpu
```

---

## Notes for Adapting This Tutorial

Before using this tutorial on a specific cluster or cloud environment, adapt:

- The `module load` line.
- The SLURM partition names.
- The number of CPUs per task.
- The number and type of GPUs requested.
- The walltime.
- The memory request.
- The filesystem paths.
- Whether the executable is `gmx` or `gmx_mpi`.

For production molecular dynamics campaigns, always validate:

- Physical correctness of the input `.tpr`.
- Equilibration protocol.
- Time step.
- Thermostat and barostat settings.
- Constraints.
- Neighbor-list settings.
- Checkpointing strategy.
- Reproducibility requirements.
```
