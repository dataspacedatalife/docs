# Running WRF 4.6.1 on the EESSI Environment

This guide explains how to run a basic WRF test case using the WRF 4.6.1 installation available through EESSI.
The example uses the `em_quarter_ss` idealized test case and runs both `ideal.exe` and `wrf.exe` with MPI.
---
1. Define the WRF installation path
   
```bash
export WRFBASE=/cvmfs/software.eessi.io/versions/2025.06/software/linux/x86_64/amd/zen3/software/WRF/4.6.1-foss-2024a-dmpar/WRFV4.6.1/
```
This variable will be used to access the WRF executables, runtime tables, and example input files.
---
2. Available WRF test cases
The WRF installation includes several predefined test cases that can be used as examples or validation runs.
They are located in:
```bash
/cvmfs/software.eessi.io/versions/2025.06/software/linux/x86_64/amd/zen3/software/WRF/4.6.1-foss-2024a-dmpar/WRFV4.6.1/test
```
Since the `WRFBASE` variable points to the WRF installation directory, the test cases can also be accessed with:
```bash
$WRFBASE/test
```
You can inspect the available test cases with:
```bash
ls $WRFBASE/test
```
In this guide, we use the `em_quarter_ss` test case, which is available at:
```bash
$WRFBASE/test/em_quarter_ss
```
---
3. Create symbolic links to the WRF executables
WRF requires two main executables for this test:
`ideal.exe`: generates the initial conditions for the idealized case.
`wrf.exe`: runs the actual WRF simulation.
Create symbolic links to both executables in your working directory:
```bash
ln -sf $WRFBASE/main/ideal.exe .
ln -sf $WRFBASE/main/wrf.exe .
```
The `-s` option creates a symbolic link, while `-f` overwrites any existing link with the same name.
---
4. Link the required WRF runtime tables
WRF needs several physics and surface parameter tables at runtime. These files are available in the `run` directory of the WRF installation.
Create symbolic links to the required tables:
```bash
ln -sf $WRFBASE/run/LANDUSE.TBL .
ln -sf $WRFBASE/run/VEGPARM.TBL .
ln -sf $WRFBASE/run/SOILPARM.TBL .
ln -sf $WRFBASE/run/GENPARM.TBL .
ln -sf $WRFBASE/run/MPTABLE.TBL .
ln -sf $WRFBASE/run/URBPARM.TBL .
```
These files provide information about land use, vegetation, soil parameters, urban parameters, and other model configuration data required by WRF.
---
5. Copy the example input files
For this example, we will use the `em_quarter_ss` idealized test case distributed with WRF. Other WRF test cases are available in `$WRFBASE/test`.
Copy the required files into the working directory:
```bash
cp -f $WRFBASE/test/em_quarter_ss/namelist.input .
cp -f $WRFBASE/test/em_quarter_ss/input_sounding .
cp -f $WRFBASE/test/em_quarter_ss/README.quarter_ss . 2>/dev/null || true
```
The files are:
`namelist.input`: main WRF configuration file.
`input_sounding`: atmospheric sounding used to initialize the idealized case.
`README.quarter_ss`: optional documentation for the test case.
The final command suppresses errors if the README file is not present.
---
6. Run `ideal.exe`
Before running the WRF simulation, the initial conditions must be generated with `ideal.exe`.
Submit the job with:
```bash
sbatch --wrap="mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./ideal.exe" -p gpu-a100
```
This command submits a Slurm job to the `gpu-a100` partition.
The MPI command uses 4 processes:
```bash
mpirun -np 4
```
The additional OpenMPI options are used to specify the communication layers:
```bash
--mca pml ob1 --mca btl self,vader,tcp
```
After the job finishes, `ideal.exe` should generate the initial condition files required by `wrf.exe`.
---
7. Run `wrf.exe`
Once `ideal.exe` has completed successfully, submit the WRF simulation:
```bash
sbatch --wrap="mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./wrf.exe" -p gpu-a100
```
This launches `wrf.exe` using 4 MPI processes in the same Slurm partition.
---
8. Check whether the simulation completed successfully
WRF writes its main log information to files named `rsl.out.*`.
To check whether the simulation finished correctly, run:
```bash
grep -i "SUCCESS COMPLETE WRF" rsl.out.0000
```
If the simulation was successful, you should see a message similar to:
```text
SUCCESS COMPLETE WRF
```
If this message does not appear, inspect the `rsl.out.0000` and `rsl.error.0000` files to identify the error.
---
9. Check the output files
WRF output files usually follow the pattern:
```bash
wrfout_d01_*
```
To list the generated output files, run:
```bash
ls -lh wrfout_d01_*
```
A successful run should produce one or more files named similarly to:
```text
wrfout_d01_YYYY-MM-DD_HH:MM:SS
```
These files contain the WRF simulation output for domain `d01`.
---
10. Complete command summary
The full sequence of commands is:
```bash
export WRFBASE=/cvmfs/software.eessi.io/versions/2025.06/software/linux/x86_64/amd/zen3/software/WRF/4.6.1-foss-2024a-dmpar/WRFV4.6.1/

ln -sf $WRFBASE/main/ideal.exe .
ln -sf $WRFBASE/main/wrf.exe .

ln -sf $WRFBASE/run/LANDUSE.TBL .
ln -sf $WRFBASE/run/VEGPARM.TBL .
ln -sf $WRFBASE/run/SOILPARM.TBL .
ln -sf $WRFBASE/run/GENPARM.TBL .
ln -sf $WRFBASE/run/MPTABLE.TBL .
ln -sf $WRFBASE/run/URBPARM.TBL .

cp -f $WRFBASE/test/em_quarter_ss/namelist.input .
cp -f $WRFBASE/test/em_quarter_ss/input_sounding .
cp -f $WRFBASE/test/em_quarter_ss/README.quarter_ss . 2>/dev/null || true

sbatch --wrap="mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./ideal.exe" -p gpu-a100

sbatch --wrap="mpirun -np 4 --mca pml ob1 --mca btl self,vader,tcp ./wrf.exe" -p gpu-a100

grep -i "SUCCESS COMPLETE WRF" rsl.out.0000

ls -lh wrfout_d01_*
```
---
11. Notes
Make sure that all commands are executed from the same working directory.
`ideal.exe` must be run before `wrf.exe`.
The test cases included with WRF can be found in `$WRFBASE/test`.
The `rsl.out.0000` file is the main file to check for successful completion.
If the simulation fails, inspect both:
```bash
rsl.out.0000
rsl.error.0000
```
The example shown here uses 4 MPI processes. For larger simulations, the number of MPI processes and the Slurm submission settings should be adapted to the available resources and the size of the WRF domain.
