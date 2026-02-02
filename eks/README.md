# Scenario: Cloud Flux on EKS

This scenario deploys a persistent Flux "MiniCluster" on an Amazon EKS cluster.

## 📁 Directory Structure

- `deploy.sh`: Deploys the EKS cluster (via Terraform) and Flux.
- `verify-hostname.sh`: Verifies the deployment with a basic hostname job.
- `run-benchmark.sh`: Submits OSU Micro-Benchmarks to the cluster.
- `check-benchmark.sh`: Monitors status and attaches to the latest benchmark job.
- `cleanup.sh`: Removes the Flux cluster (keeps EKS infra).
- `flux.yaml`: Flux MiniCluster manifest.
- `monitoring-values.yaml`: Helm values for EKS Prometheus/Grafana (if applicable).

## 🚀 Usage

### 1. Deploy
```bash
./eks/deploy.sh
```
*   Sets up AWS infrastructure (terraform).
*   Deploys Flux Operator and MiniCluster.

### 2. Verify
```bash
./eks/verify-hostname.sh
```

### 3. Run Benchmark
```bash
./eks/run-benchmark.sh --benchmark bw --np 2 --wait
```
*   Submits an OSU Bandwidth test.
*   Use `--wait` to see results immediately, or use `check-benchmark.sh` later.

### 4. Metrics & Monitoring
To enable Prometheus metrics for the cluster:
```bash
# 1. Deploy Prometheus stack
./eks/deploy-monitoring.sh

# 2. Start Flux Metrics Exporter (Required after every Flux deployment)
./eks/start-api.sh
```

### 5. Cleanup
```bash
./eks/cleanup.sh
```
*   **Note:** `cleanup.sh` removes both Flux workloads AND destroys the EKS infrastructure via Terraform.
