# OHDS HPC Service
# Basic Tutorial: Cluster Access, Module Loading, and Interactive Testing

## Accessing the Cluster

### Accessing the OneHealth DataSpace HPC Service Using an SSH Key (Recommended)

Open a terminal on your computer and execute a command similar to the following one: 

```bash
ssh -i ~/.ssh/id_rsa <username>@<hpc-provided-cluster>.dataspace.cesga.es
```

where: hpc-provided-cluster is hpc-compute.dataspace.cesga.es o hpc-gpu.dataspace.cesga.es


### Accessing the OneHealth DataSpace Service using Username and Password (Not recommened)

Connection using username and password is possible upon prior request. In this case, the same credentials used for other CESGA services will be used.

## Initial Environment After Login

Once connected, you will land in a login node, in the login node you can:

- Prepare your jobs
- Submit jobs to the HPC batch system (SLURM)
- Transfer data
- Load software modules

> **Important:** The login node is intended only for lightweight tasks (compilation, script editing, job submission, and data transfer). It should not be used to run intensive computations, as this may affect other users.

## Loading Software Modules

Software is managed using the **Modules**. Before using a program, it is necessary to initialize the appropriate module environment.
```
module available
```

By default you only get the basic system modules (mpi, compilers), but you can also use the software distributed through EESSI (*European Environment for Scientific Software Installations*).

### How to initialize the EESSI Modules

There are two available EESSI versions that you can load:
- 2025.06:
```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```
- 2023.06
```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
```

This initializes the module environment (Lmod) and enables access to the installed software.

### Search for a given software package

Once the environment is initialized, you can explore the available software with:

```bash
module spider <name_of_the_software_package>
```

For example:

```bash
module spider gromacs
```

If the program appears in the list, it means that it is available in that EESSI version.


## Selecting the Appropriate EESSI Version

You migh have to verify which EESSI version contains the software you are interested in, since not all packages are available in both versions.

Observed examples:

- WRF is not included with EESSI 2023.06.
- GROMACS is included with both versions.


## Running Interactive Tests on Compute Nodes (SLURM)

For testing, compilation or simple interactive work, it is required to use a compute node in interactive mode instead of the login node.

You can start an interactive session with:
```
salloc -c <number_of_cpu_cores>
```

And then you can start an interactive session using:
```
srun --pty /bin/bash
```

### Load the Environment and Run Programs

Once inside the compute node, you should:

1. Initialize the module environment.
2. Load the required software.
3. Run your tests.

Typical example:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

When you finish remember to exit twice to finish the job so you release the underlying compute resources.
