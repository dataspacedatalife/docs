# WRF Test Tutorial

This tutorial explains how to test a WRF installation on the cluster using the `em_quarter_ss` example.

## 1. Access a compute node

First, access a compute node specifying the number of cores to use (in this example, 4 cores will be used).

To display the available node names:

```bash
sinfo -s
```

Then connect to a node:

```bash
srun --pty -n 4 -w cesgahpc3- /bin/bash
```

---

## 2. Load EESSI and WRF modules

Load the EESSI environment and then the WRF module.

To check available WRF modules:

```bash
module spider WRF
```

Load the environment and module:

```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash

module load WRF
```

---

## 3. Create the test directory

Create a working directory for the tutorial and move into it:

```bash
mkdir -p $HOME/Tutorial_WRF/em_quarter_ss
cd $HOME/Tutorial_WRF/em_quarter_ss
```

---

## 4. Create symbolic links to required files

Define the WRF installation path:

```bash
WRFBASE=/cvmfs/software.eessi.io/versions/2023.06/software/linux/x86_64/amd/zen3/software/WRF/4.4.1-foss-2022b-dmpar/WRF-4.4.1
```

Create symbolic links to the executables and required input tables:

```bash
ln -sf $WRFBASE/main/ideal.exe .
ln -sf $WRFBASE/main/wrf.exe .

ln -sf $WRFBASE/run/LANDUSE.TBL .
ln -sf $WRFBASE/run/VEGPARM.TBL .
ln -sf $WRFBASE/run/SOILPARM.TBL .
ln -sf $WRFBASE/run/GENPARM.TBL .
ln -sf $WRFBASE/run/MPTABLE.TBL .
ln -sf $WRFBASE/run/URBPARM.TBL .
```

---

## 5. Copy required test files

Copy the example input files:

```bash
cp -f $WRFBASE/test/em_quarter_ss/namelist.input .
cp -f $WRFBASE/test/em_quarter_ss/input_sounding .
cp -f $WRFBASE/test/em_quarter_ss/README.quarter_ss . 2>/dev/null || true
```

---

## 6. Run the test

Run `ideal.exe` first:

```bash
mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./ideal.exe
```

Then execute WRF:

```bash
mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./wrf.exe
```

---

## 7. Verify successful execution

Check whether the simulation completed successfully:

```bash
grep -i "SUCCESS COMPLETE WRF" rsl.out.0000
```

Check whether output files were generated:

```bash
ls -lh wrfout_d01_*
```

If the test ran correctly, the output should include:

```text
SUCCESS COMPLETE WRF
```

and one or more files named:

```text
wrfout_d01_*
```

---

## Notes

- The test uses 4 MPI processes (`-np 4`). Adjust this value according to your allocated resources.
- The `em_quarter_ss` case is a standard WRF test intended to verify that the installation and MPI execution are functioning correctly.
- Ensure that the EESSI environment has been initialized before loading modules.
