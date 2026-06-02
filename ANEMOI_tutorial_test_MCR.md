# Running ANEMOI on the AWS HPC Cluster

This guide explains how to run an **ANEMOI training job** on the AWS HPC cluster using **SLURM**.

The example is based on a GPU training job using the `g7e` partition and the command:

```bash
anemoi-training train --config-name=config
```

The workflow assumes that the user has:

- access to the AWS HPC cluster;
- a valid ANEMOI environment;
- a configuration package called `config.tar.gz`;
- access to a GPU partition such as `g7e`, `g6e` or `p5en`;
- access to the required ERA5, WRF and graph input files.

Throughout this manual, a generic user is assumed:

```bash
USER=<your_username>
```

The recommended working directory is:

```bash
/home/$USER/anemoi_test
```

The recommended scratch structure is:

```bash
$SCRATCH/anemoi/
├── datasets/
├── graphs/
└── outputs/
```

---

## 1. Connect to the cluster

Log in to the AWS HPC cluster using SSH:

```bash
ssh <your_username>@<cluster-login-node>
```

Replace `<your_username>` and `<cluster-login-node>` with the information provided for your account.

---

## 2. Check the available partitions

Before launching a job, check the status of the cluster:

```bash
sinfo
```

A typical output may look like this:

```text
PARTITION      AVAIL  TIMELIMIT  NODES  STATE NODELIST
hpc8a*            up   infinite      3  idle~ hpc8a-dy-hpc8a-96xlarge-[2-4]
hpc8a*            up   infinite      1   idle hpc8a-dy-hpc8a-96xlarge-1
hpc6id            up   infinite      4  idle~ hpc6id-dy-hpc6id-32xlarge-[1-4]
hpc6a             up   infinite      4  idle~ hpc6a-dy-hpc6a-48xlarge-[1-4]
p4d               up   infinite      1  down# p4d-dy-p4d-24xlarge-1
p4d               up   infinite      1  down~ p4d-dy-p4d-24xlarge-2
p5en              up   infinite      1  idle% p5en-dy-p5en-48xlarge-2
p5en              up   infinite      1  idle~ p5en-dy-p5en-48xlarge-1
gpu-spot-mixed    up   infinite      1  down# gpu-spot-mixed-dy-gpu-spot-mixed-1
gpu-spot-mixed    up   infinite      9  down~ gpu-spot-mixed-dy-gpu-spot-mixed-[2-10]
g6e               up   infinite      5  idle~ g6e-dy-g6e-xlarge-[4-8]
g6e               up   infinite      3  alloc g6e-dy-g6e-xlarge-[1-3]
g7e               up   infinite      6  idle~ g7e-dy-g7e-2xlarge-[3-8]
g7e               up   infinite      1  alloc g7e-dy-g7e-2xlarge-1
g7e               up   infinite      1   idle g7e-dy-g7e-2xlarge-2
```

The most relevant node states are:

| State | Meaning |
|---|---|
| `idle` | The node is available and already running. |
| `idle~` | The node is available but may need to be started dynamically. |
| `alloc` | The node is currently allocated to another job. |
| `down`, `down#`, `down~` | The node is not currently usable. |

For ANEMOI GPU training, use a GPU partition such as:

| Partition | Recommended use |
|---|---|
| `g7e` | Recommended for standard GPU tests and training jobs. |
| `g6e` | Suitable for lighter GPU tests or when `g7e` is busy. |
| `p5en` | Suitable for larger or more demanding GPU jobs. |
| `p4d` | Use only if nodes are available. |
| `gpu-spot-mixed` | Use only if nodes are available and spot interruptions are acceptable. |

---

## 3. Prepare the EESSI module environment

The cluster uses **EESSI** to provide software modules.

To initialize the EESSI 2025.06 module environment, run:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

Alternatively, for EESSI 2023.06:

```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
```

To search for available software modules:

```bash
module spider <software-name>
```

Examples:

```bash
module spider ANEMOI
module spider anemoi
module spider Python
module spider PyTorch
module spider CUDA
```

To load a module, use:

```bash
module load <module-name>
```

For example:

```bash
module load GROMACS
```

If ANEMOI is available as a module, load it using the exact name returned by `module spider`.

For example:

```bash
module load ANEMOI
```

If ANEMOI is not available as a module, use the ANEMOI virtual environment provided for the cluster.

---

## 4. Activate the ANEMOI environment

In the reference setup, ANEMOI is loaded through an existing virtual environment:

```bash
source /home/cesga/arosquete/anemoi_down_venv.sh
```

After activating the environment, check that ANEMOI is available:

```bash
which anemoi-training
anemoi-training --help
```

If `anemoi-training` is found, the environment is correctly loaded.

---

## 5. Prepare the working directory

Create a working directory:

```bash
mkdir -p /home/$USER/anemoi_test
cd /home/$USER/anemoi_test
```

Copy the ANEMOI configuration package to this directory:

```bash
cp /path/to/config.tar.gz .
```

Extract it:

```bash
tar -xzf config.tar.gz
```

After extraction, a directory called `config/` should appear:

```bash
ls -l config/
```

The expected structure is:

```text
config/
├── config.yaml
├── downscaling.yaml
├── autoencoder.yaml
├── diffusion.yaml
├── ensemble_crps.yaml
├── hierarchical.yaml
├── hierarchical_autoencoder.yaml
├── interpolator.yaml
├── interpolator_multiout.yaml
├── lam.yaml
├── multi.yaml
├── point_wise.yaml
├── stretched.yaml
├── data/
├── dataloader/
├── diagnostics/
├── graph/
├── model/
├── system/
└── training/
```

The main configuration file is:

```text
config/config.yaml
```

The launch command:

```bash
anemoi-training train --config-name=config
```

uses this file as the entry point.

---

## 6. Prepare input and output directories

Create a standard directory structure in `$SCRATCH`:

```bash
mkdir -p $SCRATCH/anemoi/datasets
mkdir -p $SCRATCH/anemoi/graphs
mkdir -p $SCRATCH/anemoi/outputs
```

The expected input files for this example are:

```text
$SCRATCH/anemoi/datasets/era5-canarias-3km-6h-1994-2000-v4.zarr
$SCRATCH/anemoi/datasets/wrf-canarias-3km-6h-1994-2000-v4.zarr
$SCRATCH/anemoi/graphs/graph_canary_256.pt
```

Check that they exist:

```bash
ls $SCRATCH/anemoi/datasets/era5-canarias-3km-6h-1994-2000-v4.zarr
ls $SCRATCH/anemoi/datasets/wrf-canarias-3km-6h-1994-2000-v4.zarr
ls $SCRATCH/anemoi/graphs/graph_canary_256.pt
```

If `$SCRATCH` is not defined, check with the cluster administrators or define a valid scratch path manually:

```bash
echo $SCRATCH
```

Example:

```bash
export SCRATCH=/path/to/your/scratch
```

---

# 7. Content of the key configuration files

The `config.tar.gz` package contains many configuration files. For this specific launch:

```bash
anemoi-training train --config-name=config
```

the key files are:

```text
config/config.yaml
config/data/downscaling.yaml
config/dataloader/downscaling.yaml
config/system/downscaling.yaml
config/graph/downscaling.yaml
config/model/downscaling.yaml
config/training/downscaling.yaml
config/training/scalers/downscaling.yaml
config/diagnostics/downscaling.yaml
config/diagnostics/plot/downscaling.yaml
config/system/hardware/slurm.yaml
```

The following sections give generic versions of these files. The hard-coded user-specific paths have been replaced by paths based on `$SCRATCH`.

---

## 7.1 `config/config.yaml`

This is the main entry point used by ANEMOI.

```yaml
defaults:
- data: downscaling
- dataloader: downscaling
- diagnostics: downscaling
- system: downscaling
- graph: downscaling
- model: downscaling
- training: downscaling
- _self_

# set to true to switch on config validation
config_validation: True
```

This file tells ANEMOI to load the following configuration blocks:

```text
config/data/downscaling.yaml
config/dataloader/downscaling.yaml
config/diagnostics/downscaling.yaml
config/system/downscaling.yaml
config/graph/downscaling.yaml
config/model/downscaling.yaml
config/training/downscaling.yaml
```

---

## 7.2 `config/data/downscaling.yaml`

This file defines the variables, datasets and preprocessing.

```yaml
# Multi-dataset data configuration for debugging with era5 and wrf
format: zarr

# Time frequency requested from dataset
frequency: 6h

# Time step of model. Must be a multiple of frequency.
timestep: 6h

datasets:
    era5:
      forcing:
      - "PSFC"
      - "Q2"
      - "T2"
      - "TP6"
      - "U10"
      - "V10"
      diagnostic: []
      processors:
        normalizer:
          _target_: anemoi.models.preprocessing.normalizer.InputNormalizer
          config:
            default: "mean-std"
            std:
            - "TP6"

    wrf:
      forcing:
      - "cos_julian_day"
      - "cos_local_time"
      - "insolation"
      - "lsm"
      - "orography"
      - "roughness"
      - "sin_julian_day"
      - "sin_local_time"
      - "cos_latitude"
      - "sin_latitude"
      - "cos_longitude"
      - "sin_longitude"
      diagnostic:
      - "PSFC"
      - "Q2"
      - "T2"
      - "TP6"
      - "U10"
      - "V10"
      processors:
        normalizer:
          _target_: anemoi.models.preprocessing.normalizer.InputNormalizer
          config:
            default: "mean-std"
            std:
            - "TP6"
            min-max:
            - "roughness"
            max:
            - "orography"
            none:
            - "cos_julian_day"
            - "cos_local_time"
            - "insolation"
            - "sin_julian_day"
            - "sin_local_time"
            - "sin_latitude"
            - "cos_latitude"
            - "sin_longitude"
            - "cos_longitude"
            - "lsm"

# Values set in the code
num_features: null
```

Main variables used in this example:

| Variable | Meaning |
|---|---|
| `PSFC` | Surface pressure |
| `Q2` | 2 m specific humidity |
| `T2` | 2 m temperature |
| `TP6` | 6-hour accumulated precipitation |
| `U10` | 10 m zonal wind component |
| `V10` | 10 m meridional wind component |

---

## 7.3 `config/dataloader/downscaling.yaml`

This file defines batch size, data loading workers and the training, validation and test periods.

```yaml
prefetch_factor: 2
pin_memory: True

# read_group_size:
#   Form subgroups of model communication groups that read data together.
#   Each reader in the group only reads 1/read_group_size of the data,
#   which is then all-gathered between the group.
#   This can reduce CPU memory usage and increase dataloader throughput.
#   The number of GPUs per model must be divisible by read_group_size.
#   To disable, set to 1.
read_group_size: ${system.hardware.num_gpus_per_model}

num_workers:
  training: 4
  validation: 4
  test: 4

batch_size:
  training: 4
  validation: 4
  test: 4

# Runs only N batches.
# If null, all batches are used.
limit_batches:
  training: null
  validation: null
  test: 20

grid_indices:
  datasets:
    era5:
      _target_: anemoi.training.data.grid_indices.FullGrid
      nodes_name: ${graph.data}
    wrf:
      _target_: anemoi.training.data.grid_indices.FullGrid
      nodes_name: ${graph.data}

training:
  datasets:
    era5:
      dataset: ${system.input.dataset}
      start: "1994-01-01"
      end: "1998-12-31"
      frequency: ${data.frequency}
      drop: []
      trajectory: null
    wrf:
      dataset: ${system.input.dataset_b}
      start: "1994-01-01"
      end: "1998-12-31"
      frequency: ${data.frequency}
      drop: []
      trajectory: null

validation_rollout: 1

validation:
  datasets:
    era5:
      dataset: ${system.input.dataset}
      start: "1999-01-01"
      end: "1999-12-31"
      frequency: ${data.frequency}
      drop: []
      trajectory: null
    wrf:
      dataset: ${system.input.dataset_b}
      start: "1999-01-01"
      end: "1999-12-31"
      frequency: ${data.frequency}
      drop: []
      trajectory: null

test:
  datasets:
    era5:
      dataset: ${system.input.dataset}
      start: "2000-01-01"
      end: "2000-12-31"
      frequency: ${data.frequency}
      drop: []
      trajectory: null
    wrf:
      dataset: ${system.input.dataset_b}
      start: "2000-01-01"
      end: "2000-12-31"
      frequency: ${data.frequency}
      drop: []
      trajectory: null
```

For a lighter test, reduce the batch size:

```yaml
batch_size:
  training: 2
  validation: 2
  test: 2
```

---

## 7.4 `config/system/downscaling.yaml`

This is one of the most important files for users. It defines the input datasets, graph file and output directory.

Generic version:

```yaml
---
defaults:
  - output: example
  - input: example
  - hardware: slurm

input:
  dataset: ${oc.env:SCRATCH}/anemoi/datasets/era5-canarias-3km-6h-1994-2000-v4.zarr
  dataset_b: ${oc.env:SCRATCH}/anemoi/datasets/wrf-canarias-3km-6h-1994-2000-v4.zarr
  graph: ${oc.env:SCRATCH}/anemoi/graphs/graph_canary_256.pt

output:
  root: ${oc.env:SCRATCH}/anemoi/outputs
```

The user must ensure that the following paths exist:

```bash
ls $SCRATCH/anemoi/datasets/era5-canarias-3km-6h-1994-2000-v4.zarr
ls $SCRATCH/anemoi/datasets/wrf-canarias-3km-6h-1994-2000-v4.zarr
ls $SCRATCH/anemoi/graphs/graph_canary_256.pt
```

---

## 7.5 `config/graph/downscaling.yaml`

This file defines the graph used by the ANEMOI encoder-processor-decoder model.

Generic version:

```yaml
---
overwrite: True

data: "wrf"
hidden: "hidden"

nodes:

  # WRF/ERA5-on-WRF shared data nodes.
  # Both datasets are assumed to be on the same WRF grid.
  wrf:
    node_builder:
      _target_: anemoi.graphs.nodes.AnemoiDatasetNodes
      dataset: "${oc.env:SCRATCH}/anemoi/datasets/wrf-canarias-3km-6h-1994-2000-v4.zarr"
    attributes:
      area_weight:
        _target_: anemoi.graphs.nodes.attributes.SphericalAreaWeights
        norm: unit-max
        fill_value: 0

  # Hidden latent mesh.
  hidden:
    node_builder:
      _target_: anemoi.graphs.nodes.TriNodes
      resolution: 5

edges:

# Encoder: WRF grid data nodes -> hidden mesh
- source_name: wrf
  target_name: hidden
  edge_builders:
  - _target_: anemoi.graphs.edges.CutOffEdges
    cutoff_factor: 0.7
    source_mask_attr_name: null
    target_mask_attr_name: null
  attributes:
    edge_length:
      _target_: anemoi.graphs.edges.attributes.EdgeLength
      norm: unit-std
    edge_dirs:
      _target_: anemoi.graphs.edges.attributes.EdgeDirection
      norm: unit-std

# Processor: hidden mesh -> hidden mesh
- source_name: hidden
  target_name: hidden
  edge_builders:
  - _target_: anemoi.graphs.edges.MultiScaleEdges
    x_hops: 1
    scale_resolutions: 5
    source_mask_attr_name: null
    target_mask_attr_name: null
  attributes:
    edge_length:
      _target_: anemoi.graphs.edges.attributes.EdgeLength
      norm: unit-std
    edge_dirs:
      _target_: anemoi.graphs.edges.attributes.EdgeDirection
      norm: unit-std

# Decoder: hidden mesh -> WRF grid data nodes
- source_name: hidden
  target_name: wrf
  edge_builders:
  - _target_: anemoi.graphs.edges.KNNEdges
    num_nearest_neighbours: 4
    source_mask_attr_name: null
    target_mask_attr_name: null
  attributes:
    edge_length:
      _target_: anemoi.graphs.edges.attributes.EdgeLength
      norm: unit-std
    edge_dirs:
      _target_: anemoi.graphs.edges.attributes.EdgeDirection
      norm: unit-std

attributes:
  nodes: {}
  edges: {}

post_processors: []
```

The most important user-specific entry is:

```yaml
dataset: "${oc.env:SCRATCH}/anemoi/datasets/wrf-canarias-3km-6h-1994-2000-v4.zarr"
```

---

## 7.6 `config/model/downscaling.yaml`

This file defines the model architecture.

```yaml
num_channels: 256
cpu_offload: False

keep_batch_sharded: True

model:
  _target_: anemoi.models.models.AnemoiModelEncProcDec

layer_kernels:
  LayerNorm:
    _target_: anemoi.models.layers.normalization.AutocastLayerNorm
  Linear:
    _target_: torch.nn.Linear
  Activation:
    _target_: torch.nn.GELU

processor:
  _target_: anemoi.models.layers.processor.GNNProcessor
  trainable_size: ${model.trainable_parameters.hidden2hidden}
  sub_graph_edge_attributes: ${model.attributes.edges}
  num_layers: 16
  num_chunks: 4
  mlp_extra_layers: 0
  cpu_offload: ${model.cpu_offload}
  gradient_checkpointing: True
  layer_kernels: ${model.layer_kernels}

encoder:
  _target_: anemoi.models.layers.mapper.GNNForwardMapper
  trainable_size: ${model.trainable_parameters.data2hidden}
  sub_graph_edge_attributes: ${model.attributes.edges}
  num_chunks: 1
  mlp_extra_layers: 0
  cpu_offload: ${model.cpu_offload}
  gradient_checkpointing: True
  layer_kernels: ${model.layer_kernels}

decoder:
  _target_: anemoi.models.layers.mapper.GNNBackwardMapper
  trainable_size: ${model.trainable_parameters.hidden2data}
  sub_graph_edge_attributes: ${model.attributes.edges}
  num_chunks: 1
  mlp_extra_layers: 0
  cpu_offload: ${model.cpu_offload}
  gradient_checkpointing: True
  layer_kernels: ${model.layer_kernels}

residual:
  _target_: anemoi.models.layers.residual.SkipConnection
  step: -1

output_mask:
  _target_: anemoi.training.utils.masks.NoOutputMask

trainable_parameters:
  data: 8
  hidden: 8
  data2hidden: 8
  hidden2data: 8
  hidden2hidden: 8

attributes:
  edges:
    - edge_length
    - edge_dirs
  nodes: []

bounding:
  - _target_: anemoi.models.layers.bounding.ReluBounding
    variables:
      - TP6
```

Notes:

- `num_channels: 256` is suitable for a first or scout run.
- Larger production runs may use `num_channels: 512`, but this requires more GPU memory.
- The `ReluBounding` layer prevents negative precipitation values for `TP6`.

---

## 7.7 `config/training/downscaling.yaml`

This file defines precision, optimizer, training task, strategy, loss functions and number of training steps.

```yaml
---
defaults:
  - scalers: downscaling

run_id: null
fork_run_id: null
transfer_learning: False
load_weights_only: False

deterministic: False

precision: 16-mixed

multistep_input: 1
multistep_output: 1

accum_grad_batches: 2

num_sanity_val_steps: 6

gradient_clip:
  val: 32.
  algorithm: value

swa:
  enabled: False
  lr: 1.e-4

optimizer:
  _target_: torch.optim.AdamW
  betas: [0.9, 0.95]

model_task: anemoi.training.train.tasks.GraphDownscaler

strategy:
  _target_: anemoi.training.distributed.strategy.DDPGroupStrategy
  num_gpus_per_model: ${system.hardware.num_gpus_per_model}
  read_group_size: ${dataloader.read_group_size}
  find_unused_parameters: True

loss_gradient_scaling: False

rollout:
  start: 1
  epoch_increment: 0
  max: 1

max_epochs: null
max_steps: 50000

lr:
  warmup: 1000
  rate: 0.625e-4
  iterations: ${training.max_steps}
  min: 3e-7

submodules_to_freeze: []

training_loss:
    datasets:
      wrf:
        _target_: anemoi.training.losses.MSELoss
        scalers: ['general_variable', 'nan_mask_weights', 'node_weights']
        ignore_nans: false

validation_metrics:
  datasets:
    wrf:
      mse:
        _target_: anemoi.training.losses.MSELoss
        scalers: ['node_weights']
        ignore_nans: true

variable_groups:
  datasets:
    wrf:
      default: sfc
      sfc:
        param: [PSFC, Q2, T2, TP6, U10, V10]

metrics:
    datasets:
      wrf:
        - PSFC
        - T2
        - U10
        - V10
```

For a shorter test run, reduce:

```yaml
max_steps: 50000
```

to, for example:

```yaml
max_steps: 1000
```

---

## 7.8 `config/training/scalers/downscaling.yaml`

This file defines the variable weights used in the loss function.

```yaml
datasets:
  era5:
    general_variable:
      _target_: anemoi.training.losses.scalers.GeneralVariableLossScaler
      weights:
        default: 1
        Q2: 0.8
        T2: 6
        U10: 0.8
        V10: 0.8
        PSFC: 10
        TP6: 0.025

    nan_mask_weights:
      _target_: anemoi.training.losses.scalers.NaNMaskScaler

    node_weights:
      _target_: anemoi.training.losses.scalers.GraphNodeAttributeScaler
      nodes_name: ${graph.data}
      nodes_attribute_name: area_weight
      norm: unit-sum

    time_steps:
      _target_: anemoi.training.losses.scalers.UniformTimeStepScaler
      multistep_output: ${training.multistep_output}

  wrf:
    general_variable:
      _target_: anemoi.training.losses.scalers.GeneralVariableLossScaler
      weights:
        default: 1
        Q2: 1.0
        T2: 8
        U10: 0.8
        V10: 0.8
        PSFC: 10
        TP6: 0.025

    nan_mask_weights:
      _target_: anemoi.training.losses.scalers.NaNMaskScaler

    node_weights:
      _target_: anemoi.training.losses.scalers.GraphNodeAttributeScaler
      nodes_name: ${graph.data}
      nodes_attribute_name: area_weight
      norm: unit-sum

    time_steps:
      _target_: anemoi.training.losses.scalers.UniformTimeStepScaler
      multistep_output: ${training.multistep_output}
```

Users should normally not modify this file unless they want to change the relative weight of each predicted variable in the loss function.

---

## 7.9 `config/diagnostics/downscaling.yaml`

This file controls checkpointing, logging and diagnostic behavior.

Generic version with MLflow disabled:

```yaml
---
defaults:
  - plot: downscaling
  - callbacks: placeholder
  - benchmark_profiler: detailed

debug:
  anomaly_detection: False

enable_checkpointing: True

checkpoint:
  every_n_minutes:
    save_frequency: 30
    num_models_saved: 3

  every_n_epochs:
    save_frequency: 1
    num_models_saved: -1

  every_n_train_steps:
    save_frequency: null
    num_models_saved: 0

log:
  wandb:
    enabled: False
    offline: False
    log_model: False
    project: 'Anemoi'
    entity: example
    gradients: False
    parameters: False

  tensorboard:
    enabled: False

  mlflow:
    _target_: anemoi.training.diagnostics.mlflow.logger.AnemoiMLflowLogger
    enabled: False
    offline: False
    authentication: False
    tracking_uri: null
    experiment_name: 'anemoi_downscaling'
    project_name: 'anemoi_project'
    system: False
    terminal: True
    run_name: null
    on_resume_create_child: True
    expand_hyperparams:
      - config
    http_max_retries: 35
    max_params_length: 2000
    save_dir: ${system.output.logs.mlflow}

  interval: 100

enable_progress_bar: True
check_val_every_n_epoch: 1
print_memory_summary: False
```

The original configuration enabled MLflow with a specific Dagshub endpoint. For a generic user, it is safer to keep:

```yaml
mlflow:
  enabled: False
```

unless the user has a valid MLflow server.

---

## 7.10 `config/diagnostics/plot/downscaling.yaml`

This file controls plotting diagnostics.

```yaml
asynchronous: True
datashader: True

frequency:
  batch: 750
  epoch: 5

parameters:
- T2
- U10
- V10
- PSFC
- Q2
- TP6

sample_idx: 0

precip_and_related_fields: [TP6]

colormaps:
  precip:
    _target_: anemoi.training.utils.custom_colormaps.MatplotlibColormapClevels
    clevels: ["#ffffff", "#04e9e7", "#019ff4", "#0300f4", "#02fd02", "#01c501", "#008e00", "#fdf802", "#e5bc00", "#fd9500", "#fd0000", "#d40000", "#bc0000", "#f800fd"]
    variables: ${diagnostics.plot.precip_and_related_fields}

datasets_to_plot: ["wrf"]

focus_areas:
  canary:
    latlon_bbox: [25.5, -20.5, 31.5, -11.5]

callbacks:
  - _target_: anemoi.training.diagnostics.callbacks.plot.PlotLoss
    dataset_names: ["wrf"]
    parameter_groups:
      moisture: [Q2]
      wind: [U10, V10]
      temperature: [T2]
      pressure: [PSFC]
      precipitation: [TP6]
    every_n_batches: ${diagnostics.plot.frequency.batch}

  - _target_: anemoi.training.diagnostics.callbacks.plot.PlotSample
    dataset_names: ["wrf"]
    sample_idx: ${diagnostics.plot.sample_idx}
    per_sample: 6
    parameters: ${diagnostics.plot.parameters}
    output_steps: ${training.multistep_output}
    every_n_batches: ${diagnostics.plot.frequency.batch}
    accumulation_levels_plot: [0, 0.05, 0.1, 0.25, 0.5, 1, 1.5, 2, 3, 4, 5, 6, 7, 100]
    precip_and_related_fields: ${diagnostics.plot.precip_and_related_fields}
    colormaps: ${diagnostics.plot.colormaps}
```

The focus area is currently the Canary Islands:

```yaml
latlon_bbox: [25.5, -20.5, 31.5, -11.5]
```

Users working on another region should modify this bounding box.

---

## 7.11 `config/system/hardware/slurm.yaml`

This file tells ANEMOI how to read the SLURM hardware environment.

```yaml
accelerator: auto
num_gpus_per_node: ${oc.decode:${oc.env:SLURM_GPUS_PER_NODE}}
num_nodes: ${oc.decode:${oc.env:SLURM_NNODES}}
num_gpus_per_model: 1
```

For a standard single-GPU job, the relevant SLURM directive is:

```bash
#SBATCH --gres=gpu:1
```

For a two-GPU job:

```bash
#SBATCH --gres=gpu:2
```

---

# 8. Files that users normally need to edit

Most users only need to edit these files:

```text
config/system/downscaling.yaml
config/graph/downscaling.yaml
config/dataloader/downscaling.yaml
config/training/downscaling.yaml
config/diagnostics/downscaling.yaml
```

| File | What to modify |
|---|---|
| `config/system/downscaling.yaml` | ERA5 dataset path, WRF dataset path, graph path and output path. |
| `config/graph/downscaling.yaml` | WRF dataset path used to build the graph nodes. |
| `config/dataloader/downscaling.yaml` | Training, validation and test dates; batch size; workers. |
| `config/training/downscaling.yaml` | Number of steps, precision, gradient accumulation and learning rate. |
| `config/diagnostics/downscaling.yaml` | MLflow, W&B, TensorBoard and checkpoint settings. |

---

# 9. Check the configuration before launching

From the working directory:

```bash
cd /home/$USER/anemoi_test
```

Check that the key files exist:

```bash
ls config/config.yaml
ls config/system/downscaling.yaml
ls config/graph/downscaling.yaml
ls config/dataloader/downscaling.yaml
ls config/model/downscaling.yaml
ls config/training/downscaling.yaml
ls config/diagnostics/downscaling.yaml
```

Check dataset and graph paths:

```bash
grep -R "dataset:" config/system config/graph
grep -R "dataset_b:" config/system
grep -R "graph:" config/system
grep -R "root:" config/system
```

Check the batch size:

```bash
grep -R "batch_size" -A 5 config/dataloader/downscaling.yaml
```

Check the number of training steps:

```bash
grep -R "max_steps" config/training/downscaling.yaml
```

Check whether MLflow is enabled:

```bash
grep -R "mlflow" -A 20 config/diagnostics/downscaling.yaml
```

---

# 10. Test ANEMOI in an interactive GPU session

Before launching a long batch job, it is recommended to test the environment interactively.

Request one GPU on the `g7e` partition:

```bash
srun -p g7e \
     --gres=gpu:1 \
     -c 8 \
     --mem=48G \
     -t 02:00:00 \
     --pty bash
```

Once the interactive session starts, load the environment:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
source /home/cesga/arosquete/anemoi_down_venv.sh
```

Check Python, ANEMOI and GPU availability:

```bash
which python
python --version

which anemoi-training
anemoi-training --help

nvidia-smi
```

Move to the ANEMOI working directory:

```bash
cd /home/$USER/anemoi_test
```

Check that the configuration exists:

```bash
ls config/config.yaml
```

Run ANEMOI:

```bash
anemoi-training train --config-name=config
```

To leave the interactive session:

```bash
exit
```

---

# 11. Create a SLURM launch script

Create a file called:

```bash
run_anemoi_g7e.sh
```

For example:

```bash
nano run_anemoi_g7e.sh
```

Paste the following content:

```bash
#!/bin/bash
#SBATCH -J anemoi_downscaling
#SBATCH -o anemoi_downscaling_%j.out
#SBATCH -e anemoi_downscaling_%j.err
#SBATCH -p g7e
#SBATCH -c 8
#SBATCH -t 10:00:00
#SBATCH --mem=48G
#SBATCH --gres=gpu:1

set -euo pipefail

echo "======================================"
echo "ANEMOI job"
echo "Job ID: $SLURM_JOB_ID"
echo "Node list: $SLURM_JOB_NODELIST"
echo "Partition: $SLURM_JOB_PARTITION"
echo "Submit directory: $SLURM_SUBMIT_DIR"
echo "CPUs per task: $SLURM_CPUS_PER_TASK"
echo "======================================"

# Load EESSI module environment
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash

# Activate ANEMOI environment
source /home/cesga/arosquete/anemoi_down_venv.sh

# Move to the directory from which the job was submitted
cd "$SLURM_SUBMIT_DIR"

echo "Checking Python..."
which python
python --version

echo "Checking ANEMOI..."
which anemoi-training
anemoi-training --help | head -n 20 || true

echo "Checking GPU..."
nvidia-smi || true

echo "Checking configuration..."
test -d config || { echo "ERROR: config/ directory not found"; exit 1; }
test -f config/config.yaml || { echo "ERROR: config/config.yaml not found"; exit 1; }

echo "Checking SCRATCH..."
echo "SCRATCH=$SCRATCH"

echo "Launching ANEMOI..."
srun anemoi-training train --config-name=config
```

Make the script executable:

```bash
chmod +x run_anemoi_g7e.sh
```

---

# 12. Submit the ANEMOI job

Submit the job with:

```bash
sbatch run_anemoi_g7e.sh
```

SLURM will return a job ID, for example:

```text
Submitted batch job 12345
```

In this example, the job ID is `12345`.

---

# 13. Monitor the job

Check the queue:

```bash
squeue -u $USER
```

Check detailed information about the job:

```bash
scontrol show job <JOBID>
```

Example:

```bash
scontrol show job 12345
```

Follow the standard output file:

```bash
tail -f anemoi_downscaling_<JOBID>.out
```

Example:

```bash
tail -f anemoi_downscaling_12345.out
```

Follow the error file:

```bash
tail -f anemoi_downscaling_<JOBID>.err
```

Example:

```bash
tail -f anemoi_downscaling_12345.err
```

---

# 14. Alternative launch script for `g6e`

If the `g7e` partition is busy, try the `g6e` partition.

Create:

```bash
run_anemoi_g6e.sh
```

with:

```bash
#!/bin/bash
#SBATCH -J anemoi_g6e
#SBATCH -o anemoi_g6e_%j.out
#SBATCH -e anemoi_g6e_%j.err
#SBATCH -p g6e
#SBATCH -c 8
#SBATCH -t 10:00:00
#SBATCH --mem=48G
#SBATCH --gres=gpu:1

set -euo pipefail

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
source /home/cesga/arosquete/anemoi_down_venv.sh

cd "$SLURM_SUBMIT_DIR"

which python
python --version

which anemoi-training
nvidia-smi || true

test -d config || { echo "ERROR: config/ directory not found"; exit 1; }
test -f config/config.yaml || { echo "ERROR: config/config.yaml not found"; exit 1; }

srun anemoi-training train --config-name=config
```

Submit with:

```bash
sbatch run_anemoi_g6e.sh
```

---

# 15. Alternative launch script for `p5en`

For larger jobs, use the `p5en` partition.

Create:

```bash
run_anemoi_p5en.sh
```

with:

```bash
#!/bin/bash
#SBATCH -J anemoi_p5en
#SBATCH -o anemoi_p5en_%j.out
#SBATCH -e anemoi_p5en_%j.err
#SBATCH -p p5en
#SBATCH -c 16
#SBATCH -t 10:00:00
#SBATCH --mem=96G
#SBATCH --gres=gpu:1

set -euo pipefail

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
source /home/cesga/arosquete/anemoi_down_venv.sh

cd "$SLURM_SUBMIT_DIR"

which python
python --version

which anemoi-training
nvidia-smi || true

test -d config || { echo "ERROR: config/ directory not found"; exit 1; }
test -f config/config.yaml || { echo "ERROR: config/config.yaml not found"; exit 1; }

srun anemoi-training train --config-name=config
```

Submit with:

```bash
sbatch run_anemoi_p5en.sh
```

---

# 16. Multi-GPU execution

ANEMOI can also be launched with more than one GPU, provided that the configuration supports distributed training.

A possible SLURM script for two GPUs on one node is:

```bash
#!/bin/bash
#SBATCH -J anemoi_2gpu
#SBATCH -o anemoi_2gpu_%j.out
#SBATCH -e anemoi_2gpu_%j.err
#SBATCH -p g7e
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=8
#SBATCH -t 10:00:00
#SBATCH --mem=96G
#SBATCH --gres=gpu:2

set -euo pipefail

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
source /home/cesga/arosquete/anemoi_down_venv.sh

cd "$SLURM_SUBMIT_DIR"

which python
python --version

which anemoi-training
nvidia-smi || true

test -d config || { echo "ERROR: config/ directory not found"; exit 1; }
test -f config/config.yaml || { echo "ERROR: config/config.yaml not found"; exit 1; }

export SLURM_GPUS_PER_NODE=${SLURM_GPUS_PER_NODE:-2}
export SLURM_NNODES=${SLURM_NNODES:-1}

srun anemoi-training train --config-name=config system=slurm
```

Important notes:

- Use multi-GPU jobs only if the ANEMOI configuration supports distributed execution.
- Start with one GPU first.
- Move to two or more GPUs only after confirming that the single-GPU run works.
- The number of SLURM tasks should match the number of GPUs.
- If distributed communication errors appear, return to a single-GPU test.

---

# 17. Expected output files

The SLURM output files are created in the submission directory.

For the recommended script, they are:

```text
anemoi_downscaling_<JOBID>.out
anemoi_downscaling_<JOBID>.err
```

Example:

```text
anemoi_downscaling_12345.out
anemoi_downscaling_12345.err
```

The ANEMOI output directory is defined in:

```text
config/system/downscaling.yaml
```

With the generic configuration used in this manual, outputs are written to:

```bash
$SCRATCH/anemoi/outputs
```

Depending on the ANEMOI configuration, this directory may contain:

```text
logs/
checkpoint/
plots/
profiler/
```

---

# 18. Cancel a job

To cancel a specific job:

```bash
scancel <JOBID>
```

Example:

```bash
scancel 12345
```

To cancel all your jobs:

```bash
scancel -u $USER
```

Use this command carefully.

---

# 19. Common problems and solutions

## Problem: `anemoi-training: command not found`

The ANEMOI environment has not been loaded correctly.

Solution:

```bash
source /home/cesga/arosquete/anemoi_down_venv.sh
which anemoi-training
```

If using EESSI modules:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
module spider ANEMOI
```

---

## Problem: `config/config.yaml` not found

The job was launched from the wrong directory, or the configuration was not extracted.

Solution:

```bash
cd /home/$USER/anemoi_test
tar -xzf config.tar.gz
ls config/config.yaml
sbatch run_anemoi_g7e.sh
```

---

## Problem: `$SCRATCH` is not defined

Check:

```bash
echo $SCRATCH
```

If empty, define a valid scratch path:

```bash
export SCRATCH=/path/to/your/scratch
```

Then create the output structure:

```bash
mkdir -p $SCRATCH/anemoi/datasets
mkdir -p $SCRATCH/anemoi/graphs
mkdir -p $SCRATCH/anemoi/outputs
```

---

## Problem: input datasets are not found

Check:

```bash
ls $SCRATCH/anemoi/datasets/era5-canarias-3km-6h-1994-2000-v4.zarr
ls $SCRATCH/anemoi/datasets/wrf-canarias-3km-6h-1994-2000-v4.zarr
ls $SCRATCH/anemoi/graphs/graph_canary_256.pt
```

Also check the configuration:

```bash
grep -R "dataset:" config/system config/graph
grep -R "dataset_b:" config/system
grep -R "graph:" config/system
```

---

## Problem: GPU not detected

Inside the job or interactive session, check:

```bash
nvidia-smi
```

Also check with Python:

```bash
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.device_count())"
```

If no GPU is detected, verify that the SLURM script contains:

```bash
#SBATCH -p g7e
#SBATCH --gres=gpu:1
```

or another valid GPU partition.

---

## Problem: out-of-memory error

Reduce the batch size in:

```text
config/dataloader/downscaling.yaml
```

For example, change:

```yaml
batch_size:
  training: 4
  validation: 4
  test: 4
```

to:

```yaml
batch_size:
  training: 2
  validation: 2
  test: 2
```

Alternatively, request more memory:

```bash
#SBATCH --mem=96G
```

or use a larger GPU partition such as `p5en`.

---

# 20. Recommended workflow summary

The recommended sequence is:

```bash
# 1. Check available partitions
sinfo

# 2. Prepare the working directory
mkdir -p /home/$USER/anemoi_test
cd /home/$USER/anemoi_test

# 3. Extract the configuration
tar -xzf config.tar.gz

# 4. Prepare scratch directories
mkdir -p $SCRATCH/anemoi/datasets
mkdir -p $SCRATCH/anemoi/graphs
mkdir -p $SCRATCH/anemoi/outputs

# 5. Load the environment
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
source /home/cesga/arosquete/anemoi_down_venv.sh

# 6. Check ANEMOI
which anemoi-training

# 7. Check input files
ls $SCRATCH/anemoi/datasets/
ls $SCRATCH/anemoi/graphs/

# 8. Submit the job
sbatch run_anemoi_g7e.sh

# 9. Monitor the job
squeue -u $USER
```

---

# 21. Recommended final SLURM script

Use this script as the standard starting point for a single-GPU ANEMOI training job on `g7e`.

Save it as:

```bash
run_anemoi_g7e.sh
```

Content:

```bash
#!/bin/bash
#SBATCH -J anemoi_downscaling
#SBATCH -o anemoi_downscaling_%j.out
#SBATCH -e anemoi_downscaling_%j.err
#SBATCH -p g7e
#SBATCH -c 8
#SBATCH -t 10:00:00
#SBATCH --mem=48G
#SBATCH --gres=gpu:1

set -euo pipefail

echo "======================================"
echo "ANEMOI job"
echo "Job ID: $SLURM_JOB_ID"
echo "Node list: $SLURM_JOB_NODELIST"
echo "Partition: $SLURM_JOB_PARTITION"
echo "Submit directory: $SLURM_SUBMIT_DIR"
echo "CPUs per task: $SLURM_CPUS_PER_TASK"
echo "======================================"

source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
source /home/cesga/arosquete/anemoi_down_venv.sh

cd "$SLURM_SUBMIT_DIR"

echo "Checking Python..."
which python
python --version

echo "Checking ANEMOI..."
which anemoi-training
anemoi-training --help | head -n 20 || true

echo "Checking GPU..."
nvidia-smi || true

echo "Checking SCRATCH..."
echo "SCRATCH=$SCRATCH"

echo "Checking configuration..."
test -d config || { echo "ERROR: config/ directory not found"; exit 1; }
test -f config/config.yaml || { echo "ERROR: config/config.yaml not found"; exit 1; }

echo "Checking configured input paths..."
grep -R "dataset:" config/system config/graph || true
grep -R "dataset_b:" config/system || true
grep -R "graph:" config/system || true
grep -R "root:" config/system || true

echo "Launching ANEMOI..."
srun anemoi-training train --config-name=config
```

Make it executable:

```bash
chmod +x run_anemoi_g7e.sh
```

Submit it:

```bash
sbatch run_anemoi_g7e.sh
```
