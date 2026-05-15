# WRF Test Tutorial

This tutorial explains how to verify that a **WRF (Weather Research and Forecasting)** installation works correctly on the cluster using the standard **`em_quarter_ss`** benchmark case.

The test checks several components simultaneously:

- Access to compute resources
- Correct WRF installation
- Availability of required files
- MPI parallel execution
- Generation of valid simulation output

The `em_quarter_ss` example is a lightweight idealized simulation distributed with WRF and commonly used to validate installations.

---

# 1. Access a Compute Node

WRF calculations should not be executed on login nodes. Instead, computational resources must be requested from the scheduler.

First inspect available nodes:

```bash
sinfo -s
```

Example output:

```text
PARTITION AVAIL TIMELIMIT NODES(A/I/O/T)
compute*     up   infinite   10/2/0/12
```

Where:

- **A** = available nodes
- **I** = idle nodes
- **O** = allocated nodes
- **T** = total nodes

Start an interactive session requesting 4 MPI tasks:

```bash
srun --pty -n 4 -w compute-187,compute-736 /bin/bash
```

Parameter explanation:

| Option | Description |
|----------|-------------|
| `srun` | Launches jobs through Slurm |
| `--pty` | Creates an interactive terminal |
| `-n 4` | Requests four MPI tasks |
| `-w` | Specifies nodes |
| `/bin/bash` | Starts a shell session |

Verify your allocation:

```bash
hostname
```

or:

```bash
echo $SLURM_JOB_NODELIST
```

---

# 2. Load EESSI and WRF Modules

The software stack is provided through **EESSI (European Environment for Scientific Software Installations)**.

Initialize the environment:

```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
```

This enables the module system and exposes scientific software.

Check available WRF installations:

```bash
module spider WRF
```

Example:

```text
WRF/4.4.1
WRF/4.5
WRF/4.6
```

Load the desired version:

```bash
module load WRF
```

Verify loaded modules:

```bash
module list
```

Example:

```text
Loaded Modules:
WRF/4.4.1
OpenMPI
netCDF
HDF5
...
```

The module automatically loads required dependencies:

- MPI
- NetCDF
- HDF5
- Compiler toolchains

---

# 3. Create a Working Directory

Avoid executing tests directly inside installation directories.

Create a personal workspace:

```bash
mkdir -p $HOME/Tutorial_WRF/em_quarter_ss
cd $HOME/Tutorial_WRF/em_quarter_ss
```

Directory structure:

```text
Tutorial_WRF/
└── em_quarter_ss/
```

Verify location:

```bash
pwd
```

Expected output:

```text
/home/username/Tutorial_WRF/em_quarter_ss
```

---

# 4. Create Symbolic Links to Required Files

WRF requires:

- Executables
- Physical parameter tables
- Configuration files

Instead of copying files, create symbolic links.

Define the WRF installation path:

```bash
WRFBASE=/cvmfs/software.eessi.io/versions/2023.06/software/linux/x86_64/amd/zen3/software/WRF/4.4.1-foss-2022b-dmpar/WRF-4.4.1
```

Create links to executables:

```bash
ln -sf $WRFBASE/main/ideal.exe .
ln -sf $WRFBASE/main/wrf.exe .
```

Explanation:

- `ideal.exe`: generates initial conditions
- `wrf.exe`: runs the simulation
- `.` : current directory
- `-s`: symbolic link
- `-f`: overwrite existing links

Verify:

```bash
ls -l
```

Example:

```text
ideal.exe -> /cvmfs/.../ideal.exe
wrf.exe -> /cvmfs/.../wrf.exe
```

---

Create links to parameter tables:

```bash
ln -sf $WRFBASE/run/LANDUSE.TBL .
ln -sf $WRFBASE/run/VEGPARM.TBL .
ln -sf $WRFBASE/run/SOILPARM.TBL .
ln -sf $WRFBASE/run/GENPARM.TBL .
ln -sf $WRFBASE/run/MPTABLE.TBL .
ln -sf $WRFBASE/run/URBPARM.TBL .
```

These contain physical model information:

| File | Purpose |
|--------|---------|
| `LANDUSE.TBL` | Land-use properties |
| `VEGPARM.TBL` | Vegetation characteristics |
| `SOILPARM.TBL` | Soil properties |
| `GENPARM.TBL` | General physical parameters |
| `MPTABLE.TBL` | Microphysics settings |
| `URBPARM.TBL` | Urban parameterization |

Missing files often cause WRF to terminate immediately.

---

# 5. Copy Required Test Files

Copy the benchmark input files:

```bash
cp -f $WRFBASE/test/em_quarter_ss/namelist.input .
cp -f $WRFBASE/test/em_quarter_ss/input_sounding .
cp -f $WRFBASE/test/em_quarter_ss/README.quarter_ss . 2>/dev/null || true
```

Files:

### `namelist.input`

Main WRF configuration file containing:

- Simulation duration
- Domain dimensions
- Physics options
- Grid spacing
- Time-step settings

### `input_sounding`

Atmospheric initial profile:

- Temperature
- Humidity
- Wind information

### `README.quarter_ss`

Optional benchmark documentation.

Verify copied files:

```bash
ls
```

Expected:

```text
ideal.exe
wrf.exe
namelist.input
input_sounding
LANDUSE.TBL
...
```

---

# 6. Run the Preprocessing Step

First execute:

```bash
mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./ideal.exe
```

Explanation:

| Parameter | Meaning |
|------------|----------|
| `mpirun` | Launch MPI processes |
| `-np 4` | Run four parallel tasks |
| `--mca pml ob1` | Select communication management |
| `--mca btl self,vader,tcp` | Communication backends |
| `ideal.exe` | Generate model initial conditions |

Communication methods:

- `self`: self communication
- `vader`: shared-memory communication
- `tcp`: network communication

This generates:

```text
wrfinput_d01
```

Check:

```bash
ls wrfinput*
```

---

# 7. Run WRF

Launch the simulation:

```bash
mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./wrf.exe
```

During execution WRF creates log files:

```text
rsl.out.0000
rsl.out.0001
rsl.error.0000
...
```

Each MPI process generates independent logs.

Monitor execution:

```bash
tail -f rsl.out.0000
```

You should observe simulation progress and time-step updates.

---

# 8. Verify Successful Execution

Search for successful completion:

```bash
grep -i "SUCCESS COMPLETE WRF" rsl.out.0000
```

Expected output:

```text
SUCCESS COMPLETE WRF
```

This indicates that WRF finished normally.

---

# 9. Verify Output Generation

Check generated output:

```bash
ls -lh wrfout_d01_*
```

Example:

```text
-rw-r--r-- 1 user users 45M wrfout_d01_0001-01-01_00:00:00
```

WRF output files are NetCDF datasets containing:

- Pressure
- Temperature
- Winds
- Humidity
- Model variables

Inspect metadata:

```bash
ncdump -h wrfout_d01_*
```

These files can later be visualized using:

- Python (`xarray`, `netCDF4`)
- ncview
- NCL
- ParaView

---

# Troubleshooting

## Missing executable

Error:

```bash
./wrf.exe: No such file
```

Check:

```bash
ls -l wrf.exe
```

---

## MPI initialization issues

Error:

```bash
MPI_Init failed
```

Check loaded modules:

```bash
module list
```

---

## Missing table files

Error:

```bash
LANDUSE.TBL not found
```

Recreate symbolic links.

---

## Job hangs or stops unexpectedly

Inspect errors:

```bash
tail rsl.error.*
```

---

# Summary

Complete workflow:

1. Request compute resources
2. Load software modules
3. Create a workspace
4. Link executables and tables
5. Copy test files
6. Run `ideal.exe`
7. Run `wrf.exe`
8. Verify completion
9. Inspect outputs

If all steps complete successfully, both the WRF installation and MPI execution environment are functioning correctly.
