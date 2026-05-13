# Basic Tutorial: Cluster Access, Module Loading, and Interactive Testing

## 1. Accessing the Cluster

### 1.1 Accessing the Cluster Using an SSH Key (Not Recommended)

#### SSH Access with Key Authentication (No VPN Required)

You do not need to use a VPN to connect to the cluster. Access is performed directly through SSH using your private key.

Open a terminal on your computer and execute the following command:

```bash
ssh -i key username@ip
```

Where:

- `key` is the path to your SSH private key file.
- `username` is your cluster username.
- `ip` is the server IP address or hostname. In our case, it will be `hpc-pps-1.dataspace.cesga.es`

For example:

```bash
ssh -i ~/.ssh/id_rsa john@192.168.1.25
```

If the connection is successful, the system will ask for your key *passphrase* (if the key is protected), and you will gain access to the cluster environment.


### 1.2 Accessing the Cluster Using Username and Password (Recommended)

Connection using username and password is possible upon prior request. In this case, the same credentials used for other CESGA services will be used.

You do not need to use a VPN to connect to the cluster. Access is performed directly through SSH.

Open a terminal on your computer and execute the following command:

```bash
ssh username@hpc-pps-1.dataspace.cesga.es
```

Where:

- `username` is your cluster username.
- `ip` is `hpc-pps-1.dataspace.cesga.es`

If the connection is successful, the system will ask for your password and you will gain access to the cluster environment.



## 2. Initial Environment After Login

Once connected, you will see a terminal similar to the following:

```bash
[username@login01 ~]$
```

This indicates that you are already inside the cluster access node (*login node*).

From here you can:

- Prepare your jobs.
- Load software modules.
- Submit jobs to the queue system.
- Perform lightweight tests.

> **Important:** The login node is intended only for lightweight tasks (compilation, script editing, job submission, and data transfer). It should not be used to run intensive computations, as this may affect other users.

 

## 3. Loading Software Modules

Software on the cluster is managed using the module system. Before using a program, it is necessary to initialize the appropriate module environment.

In this cluster, software is distributed through EESSI (*European Environment for Scientific Software Installations*).

### 3.1 Initialize the EESSI Modules

You must load one of the available EESSI versions:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

or

```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
```

This initializes the module environment (Lmod) and enables access to the installed software.

### 3.2 Check Available Modules

Once the environment is initialized, you can explore the available software with:

```bash
module spider
```

This command allows you to search for available programs and versions within the loaded environment.

For example:

```bash
module spider gromacs
```

If the program appears in the list, it means that it is available in that EESSI version.



## 4. Selecting the Appropriate EESSI Version

It is necessary to verify which EESSI version works correctly for each program, since not all packages are available or compatible across all versions.

Recommended procedure:

1. Load one EESSI version.
2. Run `module spider`.
3. Verify that the desired program appears.
4. If it does not appear or does not work correctly, switch to another version.

Observed examples:

- WRF does not work with EESSI 2023.06.
- GROMACS works with both versions.



## 5. Running Interactive Tests on Compute Nodes (SLURM)

For testing or simple interactive work, it is recommended to use a compute node in interactive mode instead of the login node.

### 5.1 Check Node Status

First, check the status of the available nodes with:

```bash
sinfo
```

Look for nodes in the following states:

- `idle`
- `mix`

These nodes have available resources.

### 5.2 Access a Node in Interactive Mode

To enter a specific node in interactive mode, execute:

```bash
srun --pty -w node_name /bin/bash
```

Where:

- `node_name` is the identifier of the node you want to use (for example: `node01`).

Example:

```bash
srun --pty -w node01 /bin/bash
```

After executing the command, you will see a prompt similar to:

```bash
[username@node01 ~]$
```

This indicates that you are now working directly on a compute node.

> **Note:** If you want to work with MPI, the `srun` command is slightly different:

```bash
srun --pty -n number_of_nodes -w node_name1,node_name2 /bin/bash
```

### 5.3 Load the Environment and Run Programs

Once inside the compute node, you should:

1. Initialize the module environment.
2. Load the required software.
3. Run your tests.

Typical example:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```
