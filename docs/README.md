# Hybrid HPC & Flux Documentation

This repository supports multiple testing and demonstration scenarios for Hybrid HPC capabilities using Flux, Slurm, and Kubernetes (OrbStack/EKS).

## 🧭 Capability Matrix

| Workload | Environment | Features | Status | Guide |
|----------|-------------|----------|--------|-------|
| **Flux** | **Local (OrbStack)** | Persistent Cluster, Monitoring, OSU Benchmarks | ✅ Ready | [Guide](scenarios/orbstack-flux.md) |
| **Flux** | **Cloud (EKS)** | Multi-Node, Cloud Cost Metrics, Federation Prep | 🚧 In Progress | *(Coming Soon)* |
| **Hybrid** | **Local + Cloud** | Unified Grafana, Cross-Cluster Traffic | 🚧 In Progress | *(Coming Soon)* |
| **Slurm** | **Local (OrbStack)** | Slurm Controller, Flux-in-Slurm | 🧪 Experimental | *(See `scripts/deploy-orbstack-slinky-slurm.sh`)* |
| **Slurm+Flux** | **Local (OrbStack)** | Flux running aside Slurm | 🧪 Experimental | *(See `scripts/deploy-orbstack-slinky-slurm-flux.sh`)* |

## 🚀 Quick Start (Local Flux)

For the most stable and feature-complete local specific demonstration:

```bash
# 1. Deploy Persistent Flux Cluster
./scripts/deploy-orbstack-flux.sh

# 2. Run Network Benchmark
./scripts/submit-osu-benchmark.sh --benchmark bw --np 2 --cluster local

# 3. Verify Results
./scripts/verify-orbstack-flux.sh
```

## 📂 Documentation Structure

- **`scenarios/`**: Detailed guides for each matrix entry.
- **`LOCAL_DEVELOPMENT.md`**: General tips for storage, networking, and ARM64/Rosetta on Mac.
- **`SETUP.md`**: Initial prerequisite setup (Brew, Docker, etc.).
- **`KUBECTL_CONTEXTS.md`**: Managing OrbStack vs EKS contexts.
