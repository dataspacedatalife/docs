# Accessing and Loading GROMACS at CESGA

Several versions of GROMACS are available on the system:

```text
gromacs/4.5.7
gromacs/4.6.7
gromacs/2016.5-double
gromacs/2018.3-double
gromacs/2018.3
gromacs/2019.3-avx-512
gromacs/2019.3
gromacs/2021-PLUMED-2.7.1
gromacs/2021.1-double
gromacs/2021.1
gromacs/2021.4-plumed-2.8.0
gromacs/2021.5
gromacs/2022.1
gromacs/2023-cuda-system
gromacs/2023
```

## 1. Initialize the environment

Before loading any GROMACS version, start with a clean module environment and initialize the module system:

```bash
module --force purge

source /usr/share/lmod/8.7.65/init/bash
source /opt/cesga/Lmod-ft3/setup_ft3.sh
```

---

## 2. Check available GROMACS versions

To display all installed GROMACS modules:

```bash
module spider gromacs
```

This command lists all available versions currently installed on the system.

---

## 3. Check module dependencies

Each GROMACS version may require additional dependencies such as compilers and MPI libraries.

To determine which modules are required for a specific version:

```bash
module spider gromacs/<version>
```

Example:

```bash
module spider gromacs/2021.5
```

Example output:

```text
You will need to load all module(s) on any one of the lines below before the
"gromacs/2021.5" module is available to load.

cesga/2020 gcc/system openmpi/4.0.5_ft3
```

This means that before loading GROMACS, the following modules must be loaded:

```bash
module load cesga/2020 gcc/system openmpi/4.0.5_ft3 gromacs/2021.5
```

---

## 4. Verify the installation

Once loaded, test that GROMACS is available:

```bash
gmx
```

To check the installed version:

```bash
gmx --version
```

---

## Example: Loading GROMACS 2021.5

```bash
module --force purge

source /usr/share/lmod/8.7.65/init/bash
source /opt/cesga/Lmod-ft3/setup_ft3.sh

module load cesga/2020 gcc/system openmpi/4.0.5_ft3 gromacs/2021.5

gmx --version
```

---

# Running GROMACS Jobs with SLURM

For MPI executions, create a submission script.

## Example: `run.sh`

```bash
#!/bin/bash
#SBATCH -t 01:00:00
#SBATCH -n 8
#SBATCH --ntasks-per-node=4
#SBATCH -p thinnodes,cola-corta

module --force purge

source /usr/share/lmod/8.7.65/init/bash
source /opt/cesga/Lmod-ft3/setup_ft3.sh

module load cesga/2020 gcc/system openmpi/4.0.5_ft3 gromacs/2021.5

srun gmx_mpi
```

Submit the job with:

```bash
sbatch run.sh
```

---

# Optional: Enable command autocompletion

To activate GROMACS bash autocompletion:

```bash
source gmx_autocompletion.sh
```

This enables tab-completion for commands and options.

---

# Additional Help

GROMACS includes built-in help pages:

```bash
gmx help commands
gmx help selections
```

Useful resources:

GROMACS homepage:

https://www.gromacs.org

Documentation:

http://manual.gromacs.org/documentation/2021
