# Hardware List

## hpc-compute.dataspace.cesga.es 

 ## GPU´S

| Instancia | CPU | vCPU | Cores físicos host | RAM | GPU | Arquitectura GPU | VRAM por GPU | VRAM total | Interconnect | NVMe local | Red EFA | CUDA mín. | Driver NVIDIA mín. |
|---|---|---:|---|---:|---|---|---|---|---|---|---|---:|---:|
| `p6-b300.48xlarge` `gpu-b300` | Intel Xeon 5th Gen (Emerald Rapids) | 192 | 96 (SMT on) | 4096 GiB | 8× NVIDIA B300 | Blackwell Ultra (`sm_100a`) | 268 GB HBM3e | 2144 GB | NVLink 5 + NVSwitch | 30 TB | 6400 Gbps (EFAv4) | 13.0 | R580 |
| `p5en.48xlarge` `gpu-h200` | Intel Xeon 4th Gen (Sapphire Rapids) | 192 | 96 (SMT on) | 2048 GiB | 8× NVIDIA H200 | Hopper (`sm_90a`) | 141 GB HBM3e | 1128 GB | NVLink 4 + NVSwitch | 30 TB | 3200 Gbps (EFAv3) | 12.4 | R550 |
| `p4d.24xlarge` `gpu-a100` | Intel Xeon 2nd Gen (Cascade Lake 8275CL) | 96 | 48 (dual socket) | 1152 GiB | 8× NVIDIA A100 | Ampere (`sm_80`) | 40 GB HBM2e | 320 GB | NVLink 3 + NVSwitch | 8 TB | 400 Gbps (EFAv1) | 11.0 | R470 |
| `g6e.xlarge` `l40s-gpu` | AMD EPYC 7R13 Processor | 4 | — | 32 GiB | 1× NVIDIA L40S | Ada Lovelace | 48 GB GDDR6 | 48 GB | PCIe | 250 GiB | ENA (IP traffic) | — | — |
| `g7e.2xlarge` `rtx6000pro` | Intel Xeon Scalable (Emerald Rapids) | 8 | — | 62 GiB | 1× NVIDIA GB202 | Blackwell | 96 GB GDDR7 | 96 GB | PCIe Gen5 | 1900 GiB | — | — | — |


## CPU´S

| Instancia | CPU | Sockets | Cores físicos | SMT (Hyperthreading) | vCPU | Freq. max | RAM | Canales de memoria | NVMe local | Red EFA | ENA (IP traffic) | ISA extensions |
|---|---|---:|---:|---|---|---|---|---|---|---|---:|---|
| `hpc8a.96xlarge` `cpu-best-amd` | AMD EPYC 5th Gen 9004 (Turin) | 2 (96 cores/socket) | 192 | Off (1 thread/core) | 192 | 4.5 GHz | 768 GiB | 12 DDR5 | No | 300 Gbps | 300 Gbps | AVX-512, VNNI, BF16 |
| `hpc6id.32xlarge` `cpu-mixed-dy-intel-` | Intel Xeon 3rd Gen (Ice Lake) | 1 | 64 | Off (1 thread/core) | 64 | 3.5GHz | 1024 GiB | 8 DDR4 | 15.2 TB | 200 Gbps | 200 Gbps | AVX-512, VNNI, BF16 |
| `hpc6a.48xlarge` `cpu-mixed-dy-amd-96c`| AMD EPYC 7R13 Processor (Milan) | 2 | 48 | Off (1 thread/core) | 96 | 2.95GHz | 384 GiB | 12 DDR5 | No | 100 Gbps | 100 Gbps | — |
| `hpc7a.96xlarge` `cpu-mixed-dy-amd-192c` | AMD EPYC 9R14 Processor | 2 | 192 (96x2) | Off (1 thread/core) | 192 | 3.7GHz | 768 GiB | 12 DDR5 | No | 300 Gbps | 25 Gbps | AVX-512, VNNI, BF16 |
