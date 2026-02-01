# Scenario: Local Flux on OrbStack

This scenario deploys a persistent Flux "MiniCluster" on a local Kubernetes environment (OrbStack). It is the primary development and testing environment for validating workloads before cloud deployment.

## ✅ Capabilities

- **Persistent Cluster:** A single-node Flux worker pool that stays alive (`tail -f /dev/null`) to accept multiple job submissions.
- **Observability:** Prometheus scraping enabled via `ServiceMonitor`. Labels `cluster=local`, `location=orbstack`, `cost-tier=free`.
- **Workloads:** Supports MPI jobs (OSU Micro-Benchmarks) and standard Flux jobs.
- **Architecture:** x86_64 emulation via Rosetta 2 (required for Flux on Apple Silicon).

## 🛠 Deployment

### 1. Prerequisites
Ensure you have OrbStack installed and prerequisites met:
```bash
./scripts/setup.sh
```

### 2. Deploy Cluster
This script installs the Flux Operator and applies the MiniCluster manifest:
```bash
./scripts/deploy-orbstack-flux.sh
```

### 3. Verify
Run the verification suite which checks pods, services, and runs a simple hostname job:
```bash
./scripts/verify-orbstack-flux.sh
```

## 🧪 Running Benchmarks

We provide a helper script to compile (if needed) and run OSU Micro-Benchmarks inside the persistent cluster.

### Bandwidth Test
```bash
./scripts/submit-osu-benchmark.sh --benchmark bw --np 2 --cluster local --context orbstack
```

### All-Reduce Test
```bash
./scripts/submit-osu-benchmark.sh --benchmark allreduce --np 4 --cluster local --context orbstack
```

*Note: The script automatically handles `sudo -u fluxuser` execution to avoid root permission issues with MPI.*

## 🧹 Cleanup

To remove the Flux cluster (keeps monitoring stack):
```bash
./scripts/cleanup-orbstack-flux.sh
```

To remove the monitoring stack (Prometheus/Grafana):
```bash
./scripts/cleanup-monitoring-local.sh
```
