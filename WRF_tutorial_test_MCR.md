# Running WRF on the HPC Cluster with EESSI

This document provides a practical guide to running the Weather Research and Forecasting model, WRF, on the HPC cluster using the EESSI software stack.
The procedure described here is based on a successful test run performed in a generic WRF working directory:

```bash
/home/<user>/wrf_real_test
```

Replace `<user>` with your actual HPC username.

Important note about job submission: During the tests, submitting the WRF job directly with `sbatch` from the login node caused problems related to the MPI execution environment.
The working solution was: Request an interactive compute node. From inside that interactive node, submit the WRF batch job with `sbatch`. Exit the interactive node after the batch job has been submitted.
This approach avoids the environment conflicts observed when submitting directly from the login node. A possible explanation is that, when the job is submitted directly from the login node, Slurm may inherit environment variables and modules that later conflict with the MPI runtime. In contrast, when the submission is made from an interactive compute node, the execution environment appears to be cleaner and the batch job runs correctly.
For this reason, the recommended workflow is to submit the WRF batch job from an interactive node.


# 2. Load the EESSI environment
WRF is available through the EESSI software stack.
To initialize the EESSI environment, use:
```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```
To search for the WRF module:
```bash
module spider WRF
```
To load WRF:
```bash
module load WRF
```
In the batch script provided below, these steps are included explicitly to ensure that the job starts from a clean environment.

# 3. Recommended workflow
Step 1: Go to the WRF working directory
Move to the directory containing your WRF input files, `real.exe`, `wrf.exe`, and the corresponding configuration files.
For example:
```bash
cd /home/<user>/wrf_real_test
```
A typical WRF run directory should contain files such as:
```text
real.exe
wrf.exe
namelist.input
wrfbdy_d01
wrfinput_d01
```
Depending on the simulation setup, additional domain files may also be present, for example:
```text
wrfinput_d02
wrfinput_d03
```
---
Step 2: Request an interactive compute node
Before submitting the WRF job, request an interactive node.
The tested command was:
```bash
srun --pty -n 96 -w hpc8a-dy-hpc8a-96xlarge-2 /bin/bash
```
This opens an interactive shell on the selected compute node.
Explanation of the options:
`srun`: starts an interactive Slurm allocation.
`--pty`: allocates a pseudo-terminal so that you obtain an interactive shell.
`-n 96`: requests 96 tasks.
`-w hpc8a-dy-hpc8a-96xlarge-2`: requests a specific compute node.
`/bin/bash`: starts a Bash shell on the allocated node.
If you do not need a specific node, you may omit the `-w` option and allow Slurm to choose an available node:
```bash
srun --pty -n 96 -p hpc8a /bin/bash
```
---
Step 3: Create the WRF batch script
Create a file called:
```bash
run_wrf.sh
```
with the following content:
```bash
#!/bin/bash
#SBATCH -J WRF_run
#SBATCH -p hpc8a
#SBATCH -N 1
#SBATCH --ntasks=60
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH -t 06:00:00
#SBATCH --export=NONE

# 1. Clean the environment completely
module purge
unset MODULEPATH

# 2. Initialize EESSI manually
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash

# 3. Load only the WRF module
module load WRF

# 4. Set stack size and file limits
ulimit -s unlimited
ulimit -n 65536

# 5. Move to the submission directory
cd $SLURM_SUBMIT_DIR

echo "======================================"
echo "Running WRF job"
echo "Job ID: $SLURM_JOB_ID"
echo "Node list: $SLURM_NODELIST"
echo "Submit directory: $SLURM_SUBMIT_DIR"
echo "Number of tasks: $SLURM_NTASKS"
echo "======================================"

echo "=== Running REAL ==="
mpirun -np 60 --mca pml ob1 --mca btl self,tcp ./real.exe

echo "=== Running WRF ==="
mpirun -np 60 --mca pml ob1 --mca btl self,tcp ./wrf.exe

echo "=== WRF job finished ==="
```
---
4. Explanation of the batch script
Slurm directives
```bash
#SBATCH -J WRF_run
```
Sets the job name to `WRF_run`.
```bash
#SBATCH -p hpc8a
```
Submits the job to the `hpc8a` partition.
```bash
#SBATCH -N 1
```
Requests one compute node.
```bash
#SBATCH --ntasks=60
```
Requests 60 MPI tasks.
```bash
#SBATCH --cpus-per-task=1
```
Assigns one CPU core per MPI task.
```bash
#SBATCH --exclusive
```
Requests exclusive access to the node.
```bash
#SBATCH --mem=0
```
Requests all available memory on the allocated node.
```bash
#SBATCH -t 06:00:00
```
Sets a maximum runtime of 6 hours.
```bash
#SBATCH --export=NONE
```
Prevents the job from inheriting the environment from the submission shell. This is important because it helps avoid module and MPI conflicts.
---
Environment cleanup
```bash
module purge
unset MODULEPATH
```
These commands remove previously loaded modules and clear the module search path.
This is done to avoid conflicts with modules that may have been loaded automatically or inherited from the login environment.
---
EESSI initialization
```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```
This initializes the EESSI software environment and enables the use of `module`.
---
Loading WRF
```bash
module load WRF
```
This loads the WRF module and all the dependencies required by the EESSI installation.
---
System limits
```bash
ulimit -s unlimited
ulimit -n 65536
```
These commands increase the stack size and the maximum number of open files.
WRF simulations may require large stack memory and may open many files, especially in multi-domain or long-period simulations.
---
Running `real.exe`
```bash
mpirun -np 60 --mca pml ob1 --mca btl self,tcp ./real.exe
```
This runs the WRF preprocessing executable `real.exe` using 60 MPI processes.
`real.exe` prepares the initial and boundary condition files needed by `wrf.exe`.
The MPI options:
```bash
--mca pml ob1 --mca btl self,tcp
```
force Open MPI to use the TCP transport layer. This was the configuration that worked correctly in the test.
---
Running `wrf.exe`
```bash
mpirun -np 60 --mca pml ob1 --mca btl self,tcp ./wrf.exe
```
This launches the main WRF simulation using 60 MPI processes.
---
5. Submit the job
Once you are inside the interactive node, submit the batch script:
```bash
sbatch run_wrf.sh
```
After the job has been submitted, you can exit the interactive node:
```bash
exit
```
The WRF job will continue running in the queue or on the assigned compute node.
---
6. Check the job status
To check the status of your job:
```bash
squeue -u $USER
```
To see more details about a specific job:
```bash
scontrol show job <job_id>
```
Replace `<job_id>` with the Slurm job ID returned by `sbatch`.
---
7. Output files
After submitting the job, Slurm will generate an output file, usually named:
```text
slurm-<job_id>.out
```
For example:
```text
slurm-123456.out
```
You can monitor the output while the job is running with:
```bash
tail -f slurm-<job_id>.out
```
WRF will also generate its own output and log files, typically including:
```text
rsl.out.0000
rsl.error.0000
wrfout_d01_*
```
For multi-domain simulations, you may also see:
```text
wrfout_d02_*
wrfout_d03_*
```
---
8. Checking whether `real.exe` finished correctly
After `real.exe` finishes, check the `rsl.error.0000` file:
```bash
tail -n 50 rsl.error.0000
```
A successful execution of `real.exe` should include a message similar to:
```text
SUCCESS COMPLETE REAL_EM INIT
```
If this message does not appear, check the `rsl.error.*` and `rsl.out.*` files for errors.
---
9. Checking whether `wrf.exe` finished correctly
After `wrf.exe` finishes, inspect the main error log:
```bash
tail -n 50 rsl.error.0000
```
A successful WRF run should include a message similar to:
```text
SUCCESS COMPLETE WRF
```
You should also verify that the expected `wrfout` files were generated:
```bash
ls -lh wrfout*
```
---
10. Recommended directory structure
A clean structure for running WRF is:
```text
wrf_real_test/
├── namelist.input
├── real.exe
├── wrf.exe
├── met_em.d01.*
├── met_em.d02.*
├── run_wrf.sh
```
After running `real.exe`, additional files will be generated:
```text
wrfbdy_d01
wrfinput_d01
wrfinput_d02
```
After running `wrf.exe`, the main output files will be generated:
```text
wrfout_d01_*
wrfout_d02_*
rsl.out.*
rsl.error.*
```
---
11. Full recommended execution sequence
The complete sequence is:
```bash
cd /home/<user>/wrf_real_test
```
Request an interactive node:
```bash
srun --pty -n 96 -w hpc8a-dy-hpc8a-96xlarge-2 /bin/bash
```
Submit the WRF job from inside the interactive node:
```bash
sbatch run_wrf.sh
```
Exit the interactive node:
```bash
exit
```
Check the job:
```bash
squeue -u $USER
```
Monitor the output:
```bash
tail -f slurm-<job_id>.out
```
Check the WRF logs:
```bash
tail -n 50 rsl.error.0000
```
---
12. Alternative generic interactive allocation
If you do not want to request a specific node, use:
```bash
srun --pty -n 96 -p hpc8a /bin/bash
```
Then submit the job as before:
```bash
sbatch run_wrf.sh
```
---
13. Adapting the number of MPI tasks
The tested script uses:
```bash
#SBATCH --ntasks=60
```
and launches both executables with:
```bash
mpirun -np 60
```
If you change the number of tasks in the Slurm header, you must also change the number of MPI processes in both `mpirun` commands.
For example, for 96 MPI tasks:
```bash
#SBATCH --ntasks=96
```
and:
```bash
mpirun -np 96 --mca pml ob1 --mca btl self,tcp ./real.exe
mpirun -np 96 --mca pml ob1 --mca btl self,tcp ./wrf.exe
```
The number of MPI tasks should be chosen according to the domain size, number of grid points, number of domains, and available resources.
---
14. Troubleshooting
Problem: WRF fails when submitted directly from the login node
Recommended solution:
Submit the job from an interactive compute node:
```bash
srun --pty -n 96 -p hpc8a /bin/bash
sbatch run_wrf.sh
exit
```
The batch script should also contain:
```bash
#SBATCH --export=NONE
module purge
unset MODULEPATH
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module load WRF
```
---
Problem: MPI errors during execution
Use the MPI options tested successfully:
```bash
--mca pml ob1 --mca btl self,tcp
```
For example:
```bash
mpirun -np 60 --mca pml ob1 --mca btl self,tcp ./wrf.exe
```
---
Problem: `module` command not found
Make sure that EESSI is initialized:
```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```
Then check that the module system is available:
```bash
module avail
```
---
Problem: WRF module not found
Search for the WRF module:
```bash
module spider WRF
```
Then load it:
```bash
module load WRF
```
---
Problem: `real.exe` does not finish correctly
Check the log files:
```bash
tail -n 100 rsl.error.0000
```
Also check whether the input files are present:
```bash
ls -lh met_em*
ls -lh namelist.input
```
If `real.exe` finishes correctly, the log should contain:
```text
SUCCESS COMPLETE REAL_EM INIT
```
---
Problem: `wrf.exe` does not produce `wrfout` files
Check whether `real.exe` generated the required input files:
```bash
ls -lh wrfinput*
ls -lh wrfbdy_d01
```
Then inspect the WRF logs:
```bash
tail -n 100 rsl.error.0000
```
A successful WRF run should finish with:
```text
SUCCESS COMPLETE WRF
```
---
15. Final recommended batch script
Use this script as the default template for running WRF on the `hpc8a` partition:
```bash
#!/bin/bash
#SBATCH -J WRF_run
#SBATCH -p hpc8a
#SBATCH -N 1
#SBATCH --ntasks=60
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH -t 06:00:00
#SBATCH --export=NONE

module purge
unset MODULEPATH

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash

module load WRF

ulimit -s unlimited
ulimit -n 65536

cd $SLURM_SUBMIT_DIR

echo "======================================"
echo "Running WRF job"
echo "Job ID: $SLURM_JOB_ID"
echo "Node list: $SLURM_NODELIST"
echo "Submit directory: $SLURM_SUBMIT_DIR"
echo "Number of tasks: $SLURM_NTASKS"
echo "======================================"

echo "=== Running REAL ==="
mpirun -np 60 --mca pml ob1 --mca btl self,tcp ./real.exe

echo "=== Running WRF ==="
mpirun -np 60 --mca pml ob1 --mca btl self,tcp ./wrf.exe

echo "=== WRF job finished ==="
```
---
16. Summary
The tested and recommended procedure for running WRF on this HPC system is:
Prepare the WRF run directory.
Request an interactive compute node.
Submit the WRF batch job from inside the interactive node.
Exit the interactive session.
Monitor the Slurm output and WRF `rsl.*` logs.
Confirm successful execution by checking for:
```text
SUCCESS COMPLETE REAL_EM INIT
```
and:
```text
SUCCESS COMPLETE WRF
```
This workflow avoids the MPI/module conflicts observed when submitting the WRF job directly f
