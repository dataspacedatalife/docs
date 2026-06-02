# Running GROMACS on the AWS HPC Cluster

This tutorial explains how to run a basic GROMACS molecular dynamics test case on the AWS-based HPC cluster using CPU and GPU partitions. It includes EESSI module initialization, automatic download of the GROMACS test case, SLURM submission scripts, performance checks, and troubleshooting.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Cluster Partitions](#2-cluster-partitions)
3. [Recommended Partition Selection](#3-recommended-partition-selection)
4. [Loading GROMACS through EESSI](#4-loading-gromacs-through-eessi)
5. [Preparing the Working Directory](#5-preparing-the-working-directory)
6. [Downloading and Preparing the GROMACS Test Case](#6-downloading-and-preparing-the-gromacs-test-case)
7. [Interactive GROMACS Test](#7-interactive-gromacs-test)
8. [CPU Job on hpc8a](#8-cpu-job-on-hpc8a)
9. [Alternative CPU Jobs on hpc6a and hpc6id](#9-alternative-cpu-jobs-on-hpc6a-and-hpc6id)
10. [GPU Job on g6e](#10-gpu-job-on-g6e)
11. [GPU Job on g7e](#11-gpu-job-on-g7e)
12. [GPU Job on p5en](#12-gpu-job-on-p5en)
13. [Benchmarking Across Partitions](#13-benchmarking-across-partitions)
14. [Monitoring Jobs](#14-monitoring-jobs)
15. [Checking GROMACS Performance](#15-checking-gromacs-performance)
16. [Restarting from a Checkpoint](#16-restarting-from-a-checkpoint)
17. [Common Problems and Fixes](#17-common-problems-and-fixes)
18. [Practical Recommendations](#18-practical-recommendations)

---

## 1. Introduction

GROMACS is a widely used molecular dynamics package for simulating biomolecular and non-biomolecular systems, including proteins, lipids, membranes, polymers, solvents, and ion channels.

The main command used to launch a molecular dynamics simulation is:

```bash
gmx mdrun
```

or, when using an MPI-enabled GROMACS build:

```bash
gmx_mpi mdrun
```

This tutorial uses a short ion-channel benchmark/test case from the PRACE benchmark suite. The test case is **not included** in this repository. The scripts shown below download it automatically if it is not already present in the working directory.

The main input file used by GROMACS is:

```text
ion_channel.tpr
```

The `.tpr` file is a compiled GROMACS run input file. It contains the molecular system, topology, force-field parameters, simulation parameters, initial coordinates, velocities if present, constraints, and integration settings.

The basic test command is:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000
```

In this tutorial, we run only 10,000 MD steps to provide a quick validation and benchmark test.

---

## 2. Cluster Partitions

The available SLURM partitions can be inspected with:

```bash
sinfo
```

At the time of preparing this tutorial, the cluster partitions were:

```text
PARTITION      AVAIL  TIMELIMIT  NODES  STATE NODELIST
hpc8a*            up   infinite      4  idle~ hpc8a-dy-hpc8a-96xlarge-[1-4]
hpc6id            up   infinite      4  idle~ hpc6id-dy-hpc6id-32xlarge-[1-4]
hpc6a             up   infinite      4  idle~ hpc6a-dy-hpc6a-48xlarge-[1-4]
p4d               up   infinite      1  down# p4d-dy-p4d-24xlarge-1
p4d               up   infinite      1  down~ p4d-dy-p4d-24xlarge-2
p5en              up   infinite      1  idle% p5en-dy-p5en-48xlarge-1
p5en              up   infinite      1  idle~ p5en-dy-p5en-48xlarge-2
gpu-spot-mixed    up   infinite      1  down# gpu-spot-mixed-dy-gpu-spot-mixed-1
gpu-spot-mixed    up   infinite      9  down~ gpu-spot-mixed-dy-gpu-spot-mixed-[2-10]
g6e               up   infinite      5  idle~ g6e-dy-g6e-xlarge-[4-8]
g6e               up   infinite      3  alloc g6e-dy-g6e-xlarge-[1-3]
g7e               up   infinite      7  idle~ g7e-dy-g7e-2xlarge-[2-8]
g7e               up   infinite      1  alloc g7e-dy-g7e-2xlarge-1
```

The main partitions relevant for this tutorial are:

| Partition | Type | Recommended use |
|---|---:|---|
| `hpc8a` | CPU | Default CPU-only GROMACS tests |
| `hpc6a` | CPU | Alternative CPU-only tests |
| `hpc6id` | CPU | Alternative CPU-only tests, useful if local disk performance matters |
| `g6e` | GPU | First GPU validation and small GPU benchmarks |
| `g7e` | GPU | GPU validation with larger/newer GPU resources |
| `p5en` | GPU | High-end GPU benchmarking and larger production-like tests |
| `p4d` | GPU | Not recommended while nodes are down |
| `gpu-spot-mixed` | GPU | Not recommended while nodes are down |

---

## 3. Recommended Partition Selection

For this tutorial, use the following order:

```text
1. CPU validation:     hpc8a
2. Small GPU test:     g6e
3. Larger GPU test:    g7e
4. High-end GPU test:  p5en
```

Do not start directly on `p5en` unless the workflow has already been validated on `hpc8a` and `g6e`.

Recommended workflow:

```bash
sbatch submit-gromacs-hpc8a.slurm
sbatch submit-gromacs-g6e.slurm
sbatch submit-gromacs-g7e.slurm
sbatch submit-gromacs-p5en.slurm
```

Avoid `p4d` and `gpu-spot-mixed` while their nodes appear as `down` in `sinfo`.

Check their status with:

```bash
sinfo -p p4d
sinfo -p gpu-spot-mixed
```

---

## 4. Loading GROMACS through EESSI

GROMACS is provided through the **EESSI software stack**. Before loading GROMACS, users must initialize the EESSI module environment.

Two EESSI versions are available:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

or:

```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
```

For this tutorial, the recommended version is:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

After initializing EESSI, search for GROMACS with:

```bash
module spider GROMACS
```

Load GROMACS with:

```bash
module load GROMACS
```

Check that GROMACS is available:

```bash
gmx --version
```

A typical setup sequence is:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module spider GROMACS
module load GROMACS
gmx --version
```

To search for other modules, use:

```bash
module spider <MODULE_NAME>
```

For example:

```bash
module spider WRF
module spider GROMACS
```

---

## 5. Preparing the Working Directory

Create a working directory for the GROMACS test:

```bash
mkdir -p $HOME/gromacs-test
cd $HOME/gromacs-test
```

Alternatively, use a scratch directory if available:

```bash
mkdir -p /scratch/$USER/gromacs-test
cd /scratch/$USER/gromacs-test
```

Initially, the directory may contain only the scripts. After the first run, the test case will be downloaded and extracted:

```text
gromacs-test/
├── GROMACS_TestCaseA.tar.gz
├── ion_channel.tpr
├── submit-gromacs-hpc8a.slurm
├── submit-gromacs-g6e.slurm
├── submit-gromacs-g7e.slurm
└── submit-gromacs-p5en.slurm
```

---

## 6. Downloading and Preparing the GROMACS Test Case

The GROMACS test case is **not assumed to be available** in the repository or working directory.

The scripts in this tutorial download it automatically using:

```bash
curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
```

To download it manually:

```bash
curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
```

or:

```bash
wget https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
```

Extract the archive:

```bash
tar xfz GROMACS_TestCaseA.tar.gz
```

Check that the input file exists:

```bash
ls -lh ion_channel.tpr
```

Expected result:

```text
ion_channel.tpr
```

If `ion_channel.tpr` is not present after extraction, inspect the archive:

```bash
tar tf GROMACS_TestCaseA.tar.gz | head
```

---

## 7. Interactive GROMACS Test

For a quick interactive check, first initialize EESSI and load GROMACS:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module load GROMACS
gmx --version
```

Download and extract the test case:

```bash
curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
tar xfz GROMACS_TestCaseA.tar.gz
```

Run a short CPU test:

```bash
gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile
```

This produces files such as:

```text
logfile.log
ener.edr
state.cpt
```

To check performance:

```bash
grep -i "Performance" logfile.log
```

---

## 8. CPU Job on hpc8a

Create a file called:

```text
submit-gromacs-hpc8a.slurm
```

with the following content:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-hpc8a
#SBATCH --output=gmx-hpc8a-%j.out
#SBATCH --error=gmx-hpc8a-%j.err
#SBATCH --partition=hpc8a
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --time=00:30:00
#SBATCH --mem=16G

set -euo pipefail

echo "Starting GROMACS CPU job on hpc8a"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node list: ${SLURM_JOB_NODELIST}"
echo "Working directory: $(pwd)"
echo "Date: $(date)"

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module load GROMACS

echo "Loaded modules:"
module list

echo "GROMACS version:"
gmx --version

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
    echo "Downloading PRACE GROMACS Test Case A..."
    curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "Extracting GROMACS test case..."
    tar xfz GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "ERROR: ion_channel.tpr was not found after extraction."
    exit 1
fi

rm -f ener.edr logfile.log state.cpt md.log

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

echo "Running with OMP_NUM_THREADS=${OMP_NUM_THREADS}"

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

Submit the job:

```bash
sbatch submit-gromacs-hpc8a.slurm
```

Check the queue:

```bash
squeue -u $USER
```

Inspect the output:

```bash
tail -f gmx-hpc8a-<jobid>.out
```

---

## 9. Alternative CPU Jobs on hpc6a and hpc6id

To run the same job on `hpc6a`, copy the `hpc8a` script and change the partition:

```bash
cp submit-gromacs-hpc8a.slurm submit-gromacs-hpc6a.slurm
sed -i 's/--partition=hpc8a/--partition=hpc6a/' submit-gromacs-hpc6a.slurm
sed -i 's/gmx-hpc8a/gmx-hpc6a/g' submit-gromacs-hpc6a.slurm
sbatch submit-gromacs-hpc6a.slurm
```

To run on `hpc6id`:

```bash
cp submit-gromacs-hpc8a.slurm submit-gromacs-hpc6id.slurm
sed -i 's/--partition=hpc8a/--partition=hpc6id/' submit-gromacs-hpc6id.slurm
sed -i 's/gmx-hpc8a/gmx-hpc6id/g' submit-gromacs-hpc6id.slurm
sbatch submit-gromacs-hpc6id.slurm
```

This is useful for comparing CPU performance across the available CPU partitions.

---

## 10. GPU Job on g6e

Create a file called:

```text
submit-gromacs-g6e.slurm
```

with the following content:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-g6e
#SBATCH --output=gmx-g6e-%j.out
#SBATCH --error=gmx-g6e-%j.err
#SBATCH --partition=g6e
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --mem=24G

set -euo pipefail

echo "Starting GROMACS GPU job on g6e"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node list: ${SLURM_JOB_NODELIST}"
echo "Working directory: $(pwd)"
echo "Date: $(date)"

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module load GROMACS

echo "Loaded modules:"
module list

echo "GROMACS version:"
gmx --version

echo "GPU status before run:"
nvidia-smi || true

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
    echo "Downloading PRACE GROMACS Test Case A..."
    curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "Extracting GROMACS test case..."
    tar xfz GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "ERROR: ion_channel.tpr was not found after extraction."
    exit 1
fi

rm -f ener.edr logfile.log state.cpt md.log

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

echo "Running with OMP_NUM_THREADS=${OMP_NUM_THREADS}"

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

Submit the job:

```bash
sbatch submit-gromacs-g6e.slurm
```

This is the recommended first GPU test because it uses a conservative CPU/GPU layout.

---

## 11. GPU Job on g7e

Create a file called:

```text
submit-gromacs-g7e.slurm
```

with the following content:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-g7e
#SBATCH --output=gmx-g7e-%j.out
#SBATCH --error=gmx-g7e-%j.err
#SBATCH --partition=g7e
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --mem=48G

set -euo pipefail

echo "Starting GROMACS GPU job on g7e"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node list: ${SLURM_JOB_NODELIST}"
echo "Working directory: $(pwd)"
echo "Date: $(date)"

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module load GROMACS

echo "Loaded modules:"
module list

echo "GROMACS version:"
gmx --version

echo "GPU status before run:"
nvidia-smi || true

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
    echo "Downloading PRACE GROMACS Test Case A..."
    curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "Extracting GROMACS test case..."
    tar xfz GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "ERROR: ion_channel.tpr was not found after extraction."
    exit 1
fi

rm -f ener.edr logfile.log state.cpt md.log

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

echo "Running with OMP_NUM_THREADS=${OMP_NUM_THREADS}"

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

Submit the job:

```bash
sbatch submit-gromacs-g7e.slurm
```

Use `g7e` if the `g6e` test works and you want to evaluate a larger or newer GPU option.

---

## 12. GPU Job on p5en

Use `p5en` only after validating the workflow on `g6e` or `g7e`.

Create a file called:

```text
submit-gromacs-p5en.slurm
```

with the following content:

```bash
#!/bin/bash
#SBATCH --job-name=gmx-p5en
#SBATCH --output=gmx-p5en-%j.out
#SBATCH --error=gmx-p5en-%j.err
#SBATCH --partition=p5en
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --mem=128G

set -euo pipefail

echo "Starting GROMACS GPU job on p5en"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node list: ${SLURM_JOB_NODELIST}"
echo "Working directory: $(pwd)"
echo "Date: $(date)"

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module load GROMACS

echo "Loaded modules:"
module list

echo "GROMACS version:"
gmx --version

echo "GPU status before run:"
nvidia-smi || true

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
    echo "Downloading PRACE GROMACS Test Case A..."
    curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "Extracting GROMACS test case..."
    tar xfz GROMACS_TestCaseA.tar.gz
fi

if [ ! -f ion_channel.tpr ]; then
    echo "ERROR: ion_channel.tpr was not found after extraction."
    exit 1
fi

rm -f ener.edr logfile.log state.cpt md.log

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

echo "Running with OMP_NUM_THREADS=${OMP_NUM_THREADS}"

srun gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu \
    -pme gpu

echo "GPU status after run:"
nvidia-smi || true

echo "Finished at: $(date)"
```

Submit the job:

```bash
sbatch submit-gromacs-p5en.slurm
```

The `p5en` script enables both `-nb gpu` and `-pme gpu` because high-end GPU nodes are more likely to benefit from additional GPU offload.

If the job fails, simplify the `mdrun` command to:

```bash
srun gmx mdrun \
    -s ion_channel.tpr \
    -nsteps 10000 \
    -maxh 0.50 \
    -resethway \
    -noconfout \
    -g logfile \
    -ntomp "${OMP_NUM_THREADS}" \
    -nb gpu
```

---

## 13. Benchmarking Across Partitions

To compare performance across partitions, keep the same input file and number of MD steps.

Use:

```bash
-nsteps 10000
```

and compare the reported:

```text
Performance: XXX ns/day
```

Suggested benchmark table:

| Run | Partition | GPU | Suggested command options |
|---:|---|---|---|
| 1 | `hpc8a` | No | `-ntomp 32` |
| 2 | `hpc6a` | No | `-ntomp 32` |
| 3 | `hpc6id` | No | `-ntomp 32` |
| 4 | `g6e` | Yes | `-ntomp 4 -nb gpu` |
| 5 | `g7e` | Yes | `-ntomp 8 -nb gpu` |
| 6 | `p5en` | Yes | `-ntomp 16 -nb gpu -pme gpu` |

After each run, save the log file with a descriptive name:

```bash
cp logfile.log logfile_hpc8a_ntomp32.log
```

or:

```bash
cp logfile.log logfile_g6e_gpu.log
```

Then extract the performance values:

```bash
grep -i "Performance" logfile_*.log
```

---

## 14. Monitoring Jobs

Check the queue:

```bash
squeue -u $USER
```

Check the available partitions:

```bash
sinfo
```

Check a specific partition:

```bash
sinfo -p g6e
sinfo -p g7e
sinfo -p p5en
```

Inspect a running or pending job:

```bash
scontrol show job <jobid>
```

Cancel a job:

```bash
scancel <jobid>
```

Follow the SLURM output:

```bash
tail -f gmx-g6e-<jobid>.out
```

For GPU jobs, the scripts print:

```bash
nvidia-smi
```

before and after the run.

---

## 15. Checking GROMACS Performance

At the end of `logfile.log`, GROMACS prints a performance summary. Look for:

```text
Performance:      XXX ns/day
```

Extract it with:

```bash
grep -i "Performance" logfile.log
```

or inspect the end of the log:

```bash
tail -n 100 logfile.log
```

You can also search inside SLURM output files:

```bash
grep -i "Performance" gmx-*.out
```

If no performance line appears, the simulation may have failed before completing enough steps.

Search for warnings or errors:

```bash
grep -i "error\|fatal\|warning" logfile.log
```

---

## 16. Restarting from a Checkpoint

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

For production runs, it is useful to set `-maxh` slightly below the SLURM walltime so that GROMACS has time to write a checkpoint before the scheduler stops the job.

Example for a 24-hour job:

```bash
#SBATCH --time=24:00:00

gmx mdrun \
    -deffnm md \
    -cpi md.cpt \
    -append \
    -maxh 23.5
```

For GPU runs:

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

## 17. Common Problems and Fixes

### Problem 1: `module: command not found`

This usually means that the EESSI Lmod environment has not been initialized.

Fix:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

Then check:

```bash
module avail
module spider GROMACS
module load GROMACS
```

---

### Problem 2: `module load GROMACS` fails

First check that the EESSI environment is active:

```bash
module --version
```

Search for the module:

```bash
module spider GROMACS
```

If the module is not available in EESSI 2025.06, try EESSI 2023.06:

```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
module spider GROMACS
module load GROMACS
```

---

### Problem 3: `/cvmfs/software.eessi.io/...` does not exist

This means that CVMFS or the EESSI repository is not mounted on the node.

Check:

```bash
ls /cvmfs/software.eessi.io/versions/
```

If the directory does not exist, the node cannot access EESSI. Contact the cluster administrator or use a node where CVMFS is mounted correctly.

---

### Problem 4: `gmx: command not found`

Cause: GROMACS is not loaded correctly.

Fix:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module load GROMACS
which gmx
gmx --version
```

---

### Problem 5: `ion_channel.tpr: No such file or directory`

Cause: the test case was not downloaded or extracted correctly.

Fix:

```bash
curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
tar xfz GROMACS_TestCaseA.tar.gz
ls -lh ion_channel.tpr
```

If the file is still missing:

```bash
tar tf GROMACS_TestCaseA.tar.gz | head
```

---

### Problem 6: GPU requested but not used

Check whether the job is running on a GPU partition:

```bash
scontrol show job <jobid>
```

Check that a GPU is visible inside the job:

```bash
nvidia-smi
```

Check whether GROMACS was compiled with GPU support:

```bash
gmx --version | grep -i -E "GPU|CUDA|SYCL|HIP"
```

Run with explicit GPU offload:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -nb gpu
```

---

### Problem 7: CUDA out of memory

Symptoms may include:

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

### Problem 8: Poor GPU performance

Possible causes:

- Too few CPU threads feeding the GPU.
- Too many CPU threads causing overhead.
- The system is too small for the GPU.
- PME is still running on CPU.
- Bad MPI/OpenMP layout.
- Multiple jobs sharing the same GPU.
- Slow filesystem.

Try:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -ntomp 8 -nb gpu
```

Then test:

```bash
gmx mdrun -s ion_channel.tpr -nsteps 10000 -ntomp 8 -nb gpu -pme gpu
```

Compare `ns/day`.

---

### Problem 9: SLURM says GPU is unavailable

Check partition status:

```bash
sinfo
```

Check GPU partitions:

```bash
sinfo -p g6e
sinfo -p g7e
sinfo -p p5en
```

If a partition has no idle nodes, the job may remain pending.

Check why the job is pending:

```bash
squeue -j <jobid> -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"
```

---

### Problem 10: Run stops because of `-maxh`

The option:

```bash
-maxh 0.50
```

limits the run to approximately half an hour.

For longer runs, increase it:

```bash
-maxh 23.5
```

or remove it if the walltime is controlled only by SLURM.

For production runs, keep `-maxh` slightly below the SLURM walltime to allow checkpoint writing.

---

## 18. Practical Recommendations

For this cluster, the safest workflow is:

1. Start with a CPU validation job on `hpc8a`.

```bash
sbatch submit-gromacs-hpc8a.slurm
```

2. Run the first GPU test on `g6e`.

```bash
sbatch submit-gromacs-g6e.slurm
```

3. If the `g6e` job works, test `g7e`.

```bash
sbatch submit-gromacs-g7e.slurm
```

4. Use `p5en` only for larger GPU benchmarks or production-like tests.

```bash
sbatch submit-gromacs-p5en.slurm
```

5. Avoid `p4d` and `gpu-spot-mixed` while their nodes are down.

6. Always compare performance using:

```bash
grep -i "Performance" logfile.log
```

7. For the first GPU run, use only:

```bash
-nb gpu
```

8. For larger GPU nodes, test:

```bash
-nb gpu -pme gpu
```

9. Only test more aggressive GPU offload after the basic GPU run works:

```bash
-nb gpu -pme gpu -bonded gpu -update gpu
```

10. Keep the best-performing combination for the target partition.

---

## Minimal User Workflow

For most users, the minimal workflow is:

```bash
mkdir -p $HOME/gromacs-test
cd $HOME/gromacs-test
```

Create the script:

```bash
nano submit-gromacs-g6e.slurm
```

Paste the `g6e` script from this tutorial.

Submit:

```bash
sbatch submit-gromacs-g6e.slurm
```

Monitor:

```bash
squeue -u $USER
```

Check the result:

```bash
grep -i "Performance" logfile.log
```

or:

```bash
tail -n 100 logfile.log
```

---

## Notes for Adapting This Tutorial

Before using this tutorial for production simulations, adapt:

- The SLURM partition.
- The number of CPU cores.
- The number of GPUs.
- The walltime.
- The memory request.
- The input `.tpr` file.
- The output file naming convention.
- The checkpointing strategy.
- The GPU offload options.

For production molecular dynamics campaigns, always validate:

- Physical correctness of the input `.tpr`.
- Equilibration protocol.
- Time step.
- Thermostat and barostat settings.
- Constraints.
- Neighbor-list settings.
- Checkpointing strategy.
- Reproducibility requirements.
