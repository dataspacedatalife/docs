#!/bin/bash
# ORCA 6.1.1 using OpemMPI with EFA support
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

# ---------------------------------------------------------------------------
# Working directory
# ---------------------------------------------------------------------------
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instanceType=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)
workdir="${basedir}/Run/${SLURM_JOB_NAME%.*}/${SLURM_CLUSTER_NAME}/${SLURM_JOB_ID}-${SLURM_JOB_NUM_NODES}x${instanceType}-${TOTAL_CORES}-$(date "+%d-%m-%Y-%H-%M")"

echo "Nodes: ${SLURM_JOB_NUM_NODES}, Cores/node: ${SLURM_NTASKS_PER_NODE}, Total: ${TOTAL_CORES}"
echo "Execution directory: ${workdir}"
mkdir -p "${workdir}" && cd "${workdir}"

cp "$0" .

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
set +euo pipefail
source "$ORCA_ENV"
set -euo pipefail

# OpenMPI + EFA settings
export FI_PROVIDER=efa
export FI_EFA_USE_DEVICE_RDMA=1

MPI_FLAGS="--mca pml cm --mca mtl ofi --mca btl ^tcp,openib --bind-to core --map-by slot"
MPI_FLAGS="$MPI_FLAGS -x PATH -x LD_LIBRARY_PATH -x FI_PROVIDER -x FI_EFA_USE_DEVICE_RDMA"

# ---------------------------------------------------------------------------
# Build hostfile
# ---------------------------------------------------------------------------
scontrol show nodes $SLURM_NODELIST > hostfile

# ---------------------------------------------------------------------------
# System prep
# ---------------------------------------------------------------------------
echo "=== Drop caches and enable THP ==="
srun --ntasks=$SLURM_JOB_NUM_NODES --ntasks-per-node=1 /bin/bash -c "sudo /opt/cesga/software/scripts/drop_caches"
srun --ntasks=$SLURM_JOB_NUM_NODES --ntasks-per-node=1 /bin/bash -c "sudo /opt/cesga/software/scripts/enable_thp"

ulimit -s unlimited

get_timestamp() { date +%s.%N; }
elapsed_seconds() { echo "$2 $1" | awk '{printf "%.2f", $1 - $2}'; }

# ---------------------------------------------------------------------------
# Prepare case
# ---------------------------------------------------------------------------
echo "=== Preparing water input ==="
INPUT_FILENAME="water_geometry_optimization_dft_parallel_12p.inp"
INPUT="$basedir/inputs/$INPUT_FILENAME"
cp $INPUT .

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
echo "=== Running ORCA (OpenMPI) ==="
T_START=$(get_timestamp)

ORCA_EXE=$(which orca)

$ORCA_EXE $INPUT_FILENAME 2>&1 | tee ${INPUT_FILENAME%.inp}.out

T_END=$(get_timestamp)
TOTAL_TIME=$(elapsed_seconds "$T_START" "$T_END")

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
cat << REPORT

================================================================================
ORCA Results (OpenMPI)
================================================================================
Date:             $(date)
SLURM Job ID:     ${SLURM_JOB_ID}
Cluster:          ${SLURM_CLUSTER_NAME}
Nodes:            ${SLURM_JOB_NUM_NODES}
Cores per node:   ${SLURM_NTASKS_PER_NODE}
Total cores:      ${TOTAL_CORES}
Instance type:    ${instanceType}
MPI:              OpenMPI (EFA)
Working dir:      ${workdir}

Total time:       ${TOTAL_TIME}s
================================================================================
REPORT
