# GROMACS Test Tutorial (EESSI 2025.06)

This tutorial explains how to load and test the `GROMACS/2025.4-foss-2025b` installation available through EESSI. The objective is to verify that the software loads correctly, preprocessing works, and a simple molecular dynamics calculation can run successfully.

---

## 1. Start an interactive session

Launch an interactive session on a compute node:

```bash
srun -w compute-187 --pty /bin/bash
```

---

## 2. Load EESSI

Load the EESSI environment.

Available GROMACS versions include:

```text
GROMACS/2025.2-foss-2025a
GROMACS/2025.4-foss-2025b
```

Initialize EESSI:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

---

## 3. Load GROMACS

Load the desired GROMACS version:

```bash
module load GROMACS/2025.4-foss-2025b
```

Verify that the module loaded correctly:

```bash
which gmx
```

Expected output:

```text
/cvmfs/software.eessi.io/.../GROMACS/2025.4-foss-2025b/bin/gmx
```

Check version information:

```bash
gmx --version
```

Inspect:

- GROMACS version
- MPI support
- OpenMP support
- SIMD instructions

Optionally:

```bash
which gmx_mpi
```

Some installations provide MPI-enabled binaries separately.

---

## 4. Create a working directory

Create and enter a test directory:

```bash
mkdir -p $HOME/Tutorial_GROMACS
cd $HOME/Tutorial_GROMACS
```

---

## 5. Verify force field installation

Check that GROMACS topology files are available:

```bash
ls $EBROOTGROMACS/share/gromacs/top
```

You should see force fields such as:

```text
amber99.ff
amber99sb.ff
charmm27.ff
gromos54a7.ff
oplsaa.ff
```

---

## 6. Generate a water box

Create a cubic simulation box filled with water:

```bash
gmx solvate \
-cs spc216.gro \
-box 3 3 3 \
-o waterbox.gro
```

Expected output:

```text
Generated solvent containing XXXX molecules
```

Check generated files:

```bash
ls
```

Expected:

```text
waterbox.gro
```

---

## 7. Determine the number of water molecules

Count atoms:

```bash
grep SOL waterbox.gro | wc -l
```

This returns the number of atoms, not molecules.

Since water contains 3 atoms:

```text
number_of_molecules = atoms / 3
```

Example:

```text
2652 atoms / 3 = 884 molecules
```

---

## 8. Create topology

Create:

```bash
cat > topol.top << 'EOF'
#include "oplsaa.ff/forcefield.itp"
#include "oplsaa.ff/spce.itp"

[ system ]
Water box

[ molecules ]
SOL 884
EOF
```

Replace `884` with your actual value.

Verify:

```bash
cat topol.top
```

Expected:

```text
#include "oplsaa.ff/forcefield.itp"
#include "oplsaa.ff/spce.itp"

[ system ]
Water box

[ molecules ]
SOL 884
```

---

## 9. Create minimization parameters

Create:

```bash
cat > minim.mdp << 'EOF'
integrator       = steep
emtol            = 1000
nsteps           = 500

cutoff-scheme    = Verlet
nstlist          = 10

coulombtype      = PME
rcoulomb         = 1.0

vdwtype          = Cut-off
rvdw             = 1.0

pbc              = xyz
EOF
```

---

## 10. Generate binary input

Prepare the simulation:

```bash
gmx grompp \
-f minim.mdp \
-c waterbox.gro \
-p topol.top \
-o em.tpr
```

Expected:

```text
Generated em.tpr
```

No fatal errors should appear.

---

## 11. Run the calculation

Execute:

```bash
gmx mdrun -deffnm em
```

Alternatively, if MPI support is available:

```bash
srun -n 4 gmx_mpi mdrun -deffnm em
```

---

## 12. Verify successful execution

List generated files:

```bash
ls
```

Expected:

```text
em.edr
em.gro
em.log
em.tpr
em.trr
```

---

## 13. Inspect performance

Check simulation completion:

```bash
tail em.log
```

Expected:

```text
Finished mdrun
```

Performance information should appear near the end:

```text
Performance: XX ns/day
```

Performance depends on hardware and number of cores.

---

## 14. Optional scaling test

Evaluate OpenMP scaling.

Run with 1 core:

```bash
gmx mdrun -ntomp 1 -deffnm em
```

Run with 2 cores:

```bash
gmx mdrun -ntomp 2 -deffnm em
```

Run with 4 cores:

```bash
gmx mdrun -ntomp 4 -deffnm em
```

Compare:

```text
Performance: XX ns/day
```

Performance should improve as more cores are used.

---

## 15. Troubleshooting

### Module unavailable

Check available versions:

```bash
module spider GROMACS
```

---

### Command not found

Verify executable:

```bash
which gmx
```

---

### MPI executable unavailable

Check:

```bash
which gmx_mpi
```

Not all installations provide MPI-enabled binaries.

---

### Missing topology files

Verify:

```bash
echo $GMXLIB
```

or:

```bash
find $EBROOTGROMACS/share/gromacs/top
```

---

### Inspect linked libraries

To inspect dependencies:

```bash
ldd $(which gmx)
```

This helps diagnose missing libraries or broken links.

---

## 16. Cleanup

Remove tutorial files:

```bash
cd ~
rm -rf Tutorial_GROMACS
```

---

Tutorial completed successfully.

A successful run confirms:

- GROMACS loads correctly
- Force fields are accessible
- Preprocessing works
- Simulation setup works
- Execution works
- MPI/OpenMP functionality works
