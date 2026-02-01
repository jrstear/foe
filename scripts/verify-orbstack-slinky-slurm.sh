#!/bin/bash
# 🔬 Verifying Slurm-on-Kubernetes (Slinky) on OrbStack
set -e

echo "🔬 Verifying Slurm Cluster on OrbStack..."
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure we're using OrbStack context
kubectl config use-context orbstack

echo -e "${BLUE}1. Slurm Pods Status:${NC}"
kubectl get pods -n slurm
echo ""

# Get worker pod name
WORKER_POD=$(kubectl get pods -n slurm -l app.kubernetes.io/component=worker -o jsonpath='{.items[0].metadata.name}')

echo -e "${BLUE}2. Cluster Information (sinfo):${NC}"
kubectl exec -n slurm $WORKER_POD -c slurmd -- sinfo
echo ""

echo -e "${BLUE}3. Running Interactive Job (srun hostname):${NC}"
kubectl exec -n slurm $WORKER_POD -c slurmd -- srun hostname
echo ""

echo -e "${BLUE}4. Submitting Batch Job (sbatch):${NC}"
kubectl exec -n slurm $WORKER_POD -c slurmd -- sbatch --wrap="uptime; free -m"
echo ""

echo -e "${BLUE}5. Queue Status (squeue):${NC}"
kubectl exec -n slurm $WORKER_POD -c slurmd -- squeue
echo ""

echo -e "${GREEN}✓ Slurm verification complete!${NC}"
