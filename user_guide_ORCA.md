# ORCA User Guide for the OHDS HPC Service

## Quick start

1. Create a working area:

   ```bash
   mkdir -p "$HOME/orca/inputs"
   ```

2. Save an ORCA input file in:

   ```text
   $HOME/orca/inputs/water_geometry_optimization_dft_parallel_12p.inp
   ```

3. Make sure the input file contains a `%pal` block matching the SLURM task count:

   ```orca
   %pal
     nprocs 12
   end
   ```

4. Set a conservative memory value:

   ```orca
   %maxcore 1000
   ```

5. Submit the example SLURM script [orca_parallel_12p.sbatch](files/orca_parallel_12p.sbatch) and the sample [water_geometry_optimization_dft_parallel_12p.inp](files/inputs/water_geometry_optimization_dft_parallel_12p.inp):

   ```bash
   sbatch orca_parallel_12p.sbatch
   ```

6. Benchmark representative calculations before production runs. Do not assume that more cores will make ORCA faster.

## Introduction

ORCA is a quantum chemistry software package used for electronic structure calculations. It supports methods such as density functional theory, Hartree-Fock, MP2, coupled-cluster, multireference methods, semi-empirical methods, geometry optimizations, vibrational frequencies, excited-state calculations, spectroscopy, and molecular property calculations.

This guide explains how to run ORCA on the OHDS HPC service, how to prepare ORCA input files, how to submit jobs through SLURM, and how to choose an efficient number of cores.

The most important performance point for new users is that ORCA does not always become faster when more cores are used. Depending on the molecular system and method, parallel efficiency may become poor beyond a modest number of processes. Users should benchmark representative calculations before launching large production campaigns.

On 192-core OHDS CPU nodes, efficient usage often means running several independent ORCA jobs per node rather than assigning the entire node to a single ORCA calculation.

## License and access requirements

ORCA is licensed software. It is free for academic use, but it is not open-source software, and access is subject to the ORCA End User License Agreement. Commercial use requires a commercial license through FACCTs.

Before requesting ORCA access on the OHDS HPC service, users must personally register with the official ORCA forum/portal and accept the ORCA EULA.

Submit an OHDS support request with the following information:

* Full name.
* Institutional email.
* OHDS username.
* Institution, department, or research group.
* Project or allocation name.
* ORCA forum username or registered email.
* Confirmation that the intended use is academic and non-commercial.
* Requested ORCA version.

Users must not copy, redistribute, sublicense, or provide access to ORCA binaries to unauthorized users. Publications resulting from ORCA calculations should cite the ORCA version used and the relevant method-specific ORCA references.

## OHDS ORCA environment

The OHDS HPC service provides ORCA through a prepared software environment. Users normally do not need to install ORCA manually.

The example job uses the OHDS-provided ORCA 6.1.1 environment, built for OpenMPI/EFA on the `cpu-best-amd` partition:

```bash
ORCA_ENV="${ORCA_ENV:-/opt/cesga/software/orca/orca-6.1.1-avx2-env.sh}"
source "$ORCA_ENV"
```

The example job uses:

```bash
#SBATCH -p cpu-best-amd
```

These values are OHDS-specific. Check current OHDS documentation or contact OHDS support before copying them to a different partition, software version, or cluster.

## Basic ORCA input file

An ORCA input file usually contains:

1. A method and basis-set line.
2. Optional control blocks, such as parallelism and memory.
3. The molecular geometry.

Example:

```orca
! B3LYP def2-SVP TightSCF Opt

%pal
  nprocs 12
end

%maxcore 1000

* xyz 0 1
O     0.000000     0.000000     0.000000
H     0.000000     0.757000     0.586000
H     0.000000    -0.757000     0.586000
*
```

This example performs a geometry optimization of water using the B3LYP functional and the def2-SVP basis set.

The method line:

```orca
! B3LYP def2-SVP TightSCF Opt
```

means:

| Keyword | Meaning |
|---|---|
| `B3LYP` | Density functional |
| `def2-SVP` | Basis set |
| `TightSCF` | Tighter SCF convergence criterion |
| `Opt` | Geometry optimization |

The parallel block:

```orca
%pal
  nprocs 12
end
```

requests 12 ORCA processes.

The memory block:

```orca
%maxcore 1000
```

sets the approximate memory target per ORCA process in MB.

For this example:

```text
12 processes × 1000 MB/process = approximately 12000 MB
```

`%maxcore` is not a hard total job memory limit. ORCA, MPI, temporary data structures, and the operating system may use additional memory. Always leave a safety margin.

---

## Match SLURM resources with ORCA `%pal`

ORCA parallelism is controlled inside the ORCA input file using `%pal nprocs`.

For example:

```orca
%pal
  nprocs 12
end
```

This must match the SLURM resources requested in the job script:

```bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
```

Correct:

```bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
```

with:

```orca
%pal
  nprocs 12
end
```

Incorrect:

```bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
```

with:

```orca
%pal
  nprocs 48
end
```

In the incorrect case, ORCA is asked to use more processes than the job allocation provides.

Also avoid the opposite problem: requesting a full node while running only one small ORCA calculation, unless that is intentional. That would leave most of the node idle.

## Minimal working example

### Input file

File:

```text
$HOME/orca/inputs/water_geometry_optimization_dft_parallel_12p.inp
```

Content:

```orca
! B3LYP def2-SVP TightSCF Opt

%pal
  nprocs 12
end

%maxcore 1000

* xyz 0 1
O     0.000000     0.000000     0.000000
H     0.000000     0.757000     0.586000
H     0.000000    -0.757000     0.586000
*
```

### SLURM submission script

File:

```text
orca_parallel_12p.sbatch
```

Content:

```bash
#!/bin/bash
# ORCA 6.1.1 using the OHDS OpenMPI/EFA environment
#SBATCH --job-name=orca-12p
#SBATCH -p cpu-best-amd
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --time=04:00:00
#SBATCH --output=orca.o%j
#SBATCH --error=orca.e%j

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
ORCA_ENV="${ORCA_ENV:-/opt/cesga/software/orca/orca-6.1.1-avx2-env.sh}"
basedir="${BASE_DIR:-$HOME/orca}"
TOTAL_CORES=$(( SLURM_JOB_NUM_NODES * SLURM_NTASKS_PER_NODE ))

INPUT_FILENAME="water_geometry_optimization_dft_parallel_12p.inp"
INPUT="${basedir}/inputs/${INPUT_FILENAME}"

# ---------------------------------------------------------------------------
# Working directory
# ---------------------------------------------------------------------------
workdir="${basedir}/Run/${SLURM_JOB_NAME}/${SLURM_JOB_ID}"

mkdir -p "${workdir}"
cd "${workdir}"

cp "$0" .
cp "$INPUT" .

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
source "$ORCA_ENV"

# OpenMPI/EFA settings for the OHDS-provided ORCA environment.
# Do not change these unless instructed by OHDS support.
export FI_PROVIDER=efa
export FI_EFA_USE_DEVICE_RDMA=1

ulimit -s unlimited

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
ORCA_EXE="$(command -v orca)"

if [[ -z "$ORCA_EXE" ]]; then
  echo "ERROR: orca executable not found after sourcing ORCA environment." >&2
  exit 1
fi

INPUT_NPROCS="$(awk '
  BEGIN { inpal=0 }
  /^[[:space:]]*%pal/ { inpal=1 }
  inpal && /^[[:space:]]*nprocs[[:space:]]+/ { print $2; exit }
  inpal && /^[[:space:]]*end[[:space:]]*$/ { inpal=0 }
' "$INPUT_FILENAME")"

if [[ -z "$INPUT_NPROCS" ]]; then
  echo "ERROR: Could not find %pal nprocs in ${INPUT_FILENAME}." >&2
  exit 1
fi

if [[ "$INPUT_NPROCS" != "$SLURM_NTASKS_PER_NODE" ]]; then
  echo "ERROR: SLURM requested ${SLURM_NTASKS_PER_NODE} tasks per node, but ORCA input uses nprocs ${INPUT_NPROCS}." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Run ORCA
# ---------------------------------------------------------------------------
echo "ORCA executable: ${ORCA_EXE}"
echo "Input file: ${INPUT_FILENAME}"
echo "Nodes: ${SLURM_JOB_NUM_NODES}"
echo "Tasks per node: ${SLURM_NTASKS_PER_NODE}"
echo "Total allocated cores: ${TOTAL_CORES}"
echo "Execution directory: ${workdir}"

"$ORCA_EXE" "$INPUT_FILENAME" 2>&1 | tee "${INPUT_FILENAME%.inp}.out"
```

Submit the job with:

```bash
sbatch orca_parallel_12p.sbatch
```

## Run ORCA correctly

Parallel ORCA calculations should be requested in the ORCA input file, not by manually launching the ORCA driver with `mpirun`.

Use:

```bash
orca input.inp > input.out
```

or, preferably in scripts:

```bash
ORCA_EXE="$(command -v orca)"
"$ORCA_EXE" input.inp > input.out
```

Do not use:

```bash
mpirun -np 12 orca input.inp
```

Do not use:

```bash
srun orca input.inp
```

The ORCA driver reads the input file and starts the parallel modules itself when it sees the `%pal` block. Using `command -v orca` or the full path to the ORCA executable is recommended because ORCA must be able to find its auxiliary executables.

---

## Recommended directory structure

A simple directory structure is:

```text
$HOME/orca/
├── inputs/
│   ├── water_geometry_optimization_dft_parallel_12p.inp
│   ├── molecule_001.inp
│   └── molecule_002.inp
└── Run/
    └── ...
```

Recommended practice:

* Store input files in `$HOME/orca/inputs/`.
* Let the SLURM script create a fresh run directory.
* Keep one calculation per working directory.
* Avoid reusing directories containing files from previous ORCA runs.

## Memory planning

ORCA uses `%maxcore` to define the approximate memory target per process in MB.

Example:

```orca
%pal
  nprocs 12
end

%maxcore 1000
```

Approximate ORCA memory target:

```text
12 × 1000 MB = 12000 MB
```

Users should not simply divide all node memory by the number of processes and assign the maximum possible value. Leave memory for:

* The operating system.
* MPI runtime.
* ORCA overhead beyond `%maxcore`.
* Temporary data structures.
* Other packed jobs, if running several calculations on the same node.

For packed jobs, estimate memory as:

```text
number_of_jobs × nprocs_per_job × maxcore_per_process
```

Then add a safety margin. A 20-30% margin is a reasonable starting point unless you have measured memory usage for the specific workload.

Example:

```text
16 jobs × 12 processes/job × 1000 MB/process = 192000 MB
```

This is approximately 192 GB before additional overhead.

Example with a larger `%maxcore`:

```text
16 jobs × 12 processes/job × 4000 MB/process = 768000 MB
```

This reaches approximately 768 GB before overhead and is too aggressive for a 768 GiB node. In that case, reduce the number of simultaneous jobs, reduce `%maxcore`, or use a different layout.

## Check output files

A normal ORCA run produces an output file, usually with `.out` extension:

```text
water_geometry_optimization_dft_parallel_12p.out
```

Important things to check:

* ORCA version.
* Number of processes used.
* Input method and basis set.
* SCF convergence.
* Geometry optimization convergence.
* Final energy.
* Warnings.
* Error messages.
* Total wall time.

Useful commands:

```bash
grep -i "ORCA TERMINATED NORMALLY" *.out
grep -i "TOTAL RUN TIME" *.out
grep -i "FINAL SINGLE POINT ENERGY" *.out
grep -i "THE OPTIMIZATION HAS CONVERGED" *.out
grep -i "warning\|error" *.out
```

For geometry optimizations, check that the optimization converged successfully and inspect the final structure.

For benchmarking, verify that all tested process counts produce consistent final energies. If energies differ significantly, investigate before comparing performance.

## Benchmark ORCA parallelism before production runs

ORCA calculations do not always become faster when more cores are used. The optimal number of processes depends on:

* Molecular size.
* Basis set.
* Functional or wavefunction method.
* Type of calculation.
* Memory requirements.
* Disk I/O.
* MPI communication overhead.

For a new ORCA workload, select one representative input and run it with several values of `%pal nprocs`.

For small or medium calculations, a useful first set is:

```text
nprocs = 4
nprocs = 8
nprocs = 12
nprocs = 16
nprocs = 24
nprocs = 32
```

For larger systems, users may also test:

```text
nprocs = 48
nprocs = 96
```

but only if smaller tests suggest that scaling remains useful.

For each test, record:

* ORCA status.
* ORCA runtime.
* Scheduler or wrapper runtime.
* Final energy.
* Number of geometry optimization cycles, if applicable.
* Memory usage, if available.
* Warnings or MPI-related messages.

Suggested benchmark table:

| Cores | ORCA runtime | Relative speed | Final energy | Notes |
|---:|---:|---:|---:|---|
| 4 | | | | |
| 8 | | | | |
| 12 | | | | |
| 16 | | | | |
| 24 | | | | |
| 32 | | | | |

The best process count is usually not the largest number of cores. It is the value that gives the best balance between time-to-solution and efficient use of the allocated node.

---

## Benchmark example: small water DFT geometry optimization

The following benchmark was performed on the OHDS HPC service using the `cpu-best-amd` partition.

### Workload

* Software: ORCA 6.1.1, OpenMPI with EFA.
* Hardware: `cpu-best-amd` node.
* Benchmark input: water geometry optimization.
* ORCA method line:

  ```orca
  ! B3LYP def2-SVP TightSCF Opt
  ```

* Memory setting:

  ```orca
  %maxcore 1000
  ```

* Parallelism tested with `%pal nprocs` set to 12, 24, 48, and 96.
* All comparable runs used one node.
* All comparable runs completed normally.
* Each successful run converged in 4 geometry optimization cycles, followed by a final energy evaluation at the stationary point.

### Results

| Input | Cores | ORCA runtime | Wrapper runtime | Final energy (Eh) | Relative to 12 cores |
|---|---:|---:|---:|---:|---:|
| `water_geometry_optimization_dft_parallel_12p.inp` | 12 | 71.855 s | 71.93 s | -76.321269043458 | 1.00x |
| `water_geometry_optimization_dft_parallel_24p.inp` | 24 | 97.033 s | 97.11 s | -76.321269043328 | 0.74x |
| `water_geometry_optimization_dft_parallel_48p.inp` | 48 | 158.125 s | 158.21 s | -76.321269043395 | 0.45x |
| `water_geometry_optimization_dft_parallel_96p.inp` | 96 | 255.136 s | 255.21 s | -76.321269043365 | 0.28x |

### Interpretation

For this small 3-atom water DFT geometry optimization, increasing the process count made the calculation slower.

The 12-core case was the fastest completed comparable run.

Relative to the 12-core run:

| Cores | Interpretation |
|---:|---|
| 12 | Fastest completed comparable run |
| 24 | About 35% slower |
| 48 | About 120% slower |
| 96 | About 255% slower |

This behaviour is expected for a very small molecule. The actual quantum chemistry workload is small, so MPI startup, process coordination, integral/grid setup, and other parallel overheads dominate the runtime. Adding more processes increases overhead more than it reduces useful computation time.

The final energies agree to approximately `1e-10 Eh`, so the different process counts produced numerically consistent results. The problem was performance, not correctness.

This benchmark should not be interpreted as a universal rule that 12 cores is always optimal. Larger molecules, larger basis sets, hybrid functionals, RI approximations, TD-DFT, frequency calculations, MP2, coupled-cluster, and other methods may show different scaling behaviour.

## Packing multiple ORCA jobs per node

When a benchmark shows that one ORCA calculation only needs part of a node, users should pack several independent calculations on the same node.

For a 192-core node, possible packing layouts are:

```text
16 jobs × 12 cores = 192 cores
12 jobs × 16 cores = 192 cores
8 jobs × 24 cores = 192 cores
6 jobs × 32 cores = 192 cores
4 jobs × 48 cores = 192 cores
2 jobs × 96 cores = 192 cores
```

The chosen layout should be based on benchmark results and memory requirements.

For the water benchmark above, the most efficient tested value was 12 cores. Therefore, for many similar small calculations, a good packing strategy would be:

```text
16 jobs × 12 cores/job = 192 cores
```

Each packed ORCA calculation must have:

* Its own working directory.
* Its own input file.
* Its own output file.
* Its own `%pal nprocs` value.
* Enough memory according to `%maxcore × nprocs`.
* No filename collisions with other simultaneous calculations.

Bad practice:

```text
Several ORCA jobs running in the same directory with similar filenames.
```

Good practice:

```text
Run/job_001/molecule_001.inp
Run/job_001/molecule_001.out

Run/job_002/molecule_002.inp
Run/job_002/molecule_002.out
```

Packing multiple parallel ORCA jobs in one SLURM allocation should be done using a tested OHDS launcher template. Avoid improvising with `mpirun` or `srun orca`, because the ORCA driver should launch its own parallel modules from the `%pal` block. If you need a production packing template, contact OHDS support or use an OHDS-provided launcher.

## Common mistakes

### Mistake 1: SLURM and ORCA process counts do not match

Bad:

```bash
#SBATCH --ntasks-per-node=12
```

with:

```orca
%pal
  nprocs 48
end
```

Good:

```bash
#SBATCH --ntasks-per-node=12
```

with:

```orca
%pal
  nprocs 12
end
```

### Mistake 2: Running ORCA with `mpirun`

Bad:

```bash
mpirun -np 12 orca input.inp
```

Good:

```bash
orca input.inp > input.out
```

or:

```bash
ORCA_EXE="$(command -v orca)"
"$ORCA_EXE" input.inp > input.out
```

### Mistake 3: Requesting too many cores

Bad:

```text
Requesting 96 or 192 cores for a very small calculation that scales best to 12 cores.
```

Good:

```text
Benchmark first, then use the smallest efficient core count.
Pack several independent jobs per node if appropriate.
```

### Mistake 4: Using too much memory per process

Potentially bad:

```orca
%pal
  nprocs 96
end

%maxcore 8000
```

Approximate memory target:

```text
96 × 8000 MB = 768000 MB
```

This is approximately the full memory of a `cpu-best-amd` node before accounting for overhead.

Better:

* Reduce `%maxcore`.
* Reduce `nprocs`.
* Use fewer packed jobs.
* Leave a memory safety margin.

### Mistake 5: Reusing old working directories

Bad:

```text
Running a new calculation in a directory containing old ORCA temporary files.
```

Good:

```text
Create a fresh working directory for each calculation or job.
```

## Troubleshooting

| Symptom | Likely cause | What to check |
|---|---|---|
| `orca: command not found` | ORCA environment was not sourced | Check `source "$ORCA_ENV"` and `command -v orca` |
| Job fails immediately | Environment, executable path, or MPI setup problem | Check `orca.e%j`, `orca.o%j`, and the value of `ORCA_ENV` |
| Job runs with an unexpected process count | SLURM and `%pal nprocs` mismatch | Check `#SBATCH --ntasks-per-node` and `%pal nprocs` |
| Job is killed by the scheduler | Time or memory limit exceeded | Increase wall time, reduce `%maxcore`, reduce `nprocs`, or reduce packed jobs |
| Multiple jobs overwrite files | Jobs share a working directory or output filename | Use one working directory and one output file per calculation |
| More cores make the job slower | Poor scaling for the workload | Benchmark smaller `nprocs` values |
| Energies differ between benchmark runs | Runs may not be comparable | Check convergence, method, basis set, geometry, and input differences |
| Output contains warnings or errors | Method, convergence, memory, or environment problem | Search the `.out`, `.e%j`, and `.o%j` files for warnings and errors |

Useful diagnostic commands:

```bash
pwd
hostname
date
command -v orca
grep -i "ORCA TERMINATED NORMALLY" *.out
grep -i "FINAL SINGLE POINT ENERGY" *.out
grep -i "TOTAL RUN TIME" *.out
grep -i "warning\|error" *.out
```

## Recommended workflow for new users

1. Confirm that you are allowed to use ORCA under the ORCA license.
2. Request ORCA access through OHDS support.
3. Create a clean input file.
4. Start with a modest number of cores, such as 8 or 12.
5. Make sure SLURM tasks match `%pal nprocs`.
6. Submit a test job.
7. Check the ORCA output for normal termination.
8. Check the final energy and convergence.
9. Benchmark several `nprocs` values.
10. Choose the most efficient core count.
11. For production campaigns, pack multiple independent ORCA jobs per 192-core node when appropriate.
12. Monitor memory and I/O usage.
13. Keep one calculation per working directory.

---

## `cpu-best-amd` node summary

The `cpu-best-amd` partition provides AMD CPU nodes suitable for parallel scientific workloads.

Brief node summary:

| Resource | Value |
|---|---|
| Instance type | `hpc8a.96xlarge` |
| CPU | AMD EPYC 5th Gen 9004, Turin |
| Sockets | 2 |
| Physical cores | 192 |
| SMT / Hyperthreading | Off, 1 thread per core |
| RAM | 768 GiB |
| Network | EFA 300 Gbps, ENA 300 Gbps |
| Local NVMe | No |
| ISA extensions | AVX-512, VNNI, BF16 |

Practical implications:

* One node provides 192 physical cores.
* Since SMT is off, 192 SLURM tasks correspond to 192 physical cores.
* The node has substantial memory, but packed ORCA jobs must still be planned using `%maxcore × nprocs × number_of_jobs` plus a safety margin.
* There is no local NVMe, so users should keep working directories organized and avoid unnecessary temporary I/O.

These values are OHDS-specific and should be rechecked if the partition configuration changes.

## Final recommendations

For ORCA on the OHDS HPC service:

```text
Use %pal nprocs to control ORCA parallelism.
Match %pal nprocs with the SLURM task allocation.
Do not launch the ORCA driver with mpirun or srun.
Use the OHDS-provided ORCA environment.
Use the cpu-best-amd partition for AMD CPU nodes when appropriate.
Benchmark representative workloads before production runs.
Do not assume that more cores means faster ORCA.
For small or poorly scaling workloads, pack multiple independent jobs per node.
Use separate working directories for simultaneous calculations.
Check memory carefully when packing jobs.
Comply with the ORCA license and access requirements.
```

The water benchmark demonstrates the main lesson clearly: for a very small DFT geometry optimization, 12 cores was faster than 24, 48, or 96 cores. For similar workloads, efficient OHDS usage means running multiple independent ORCA calculations per 192-core node rather than increasing `%pal nprocs` beyond the useful scaling range.
