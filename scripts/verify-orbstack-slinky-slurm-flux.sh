#!/bin/bash
# 🔬 Verifying Slurm + Flux (Converged) on OrbStack
set -e

echo "🔬 Verifying Slurm-Flux Cluster on OrbStack..."
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure we're using OrbStack context
kubectl config use-context orbstack

echo -e "${BLUE}1. Slurm-Flux Pods Status:${NC}"
kubectl get pods -n slurm-flux
echo ""

# Get worker pod name
WORKER_POD=$(kubectl get pods -n slurm-flux -l app.kubernetes.io/component=worker -o jsonpath='{.items[0].metadata.name}')

echo -e "${BLUE}2. Cluster Information (sinfo):${NC}"
kubectl exec -n slurm-flux $WORKER_POD -c slurmd -- sinfo
echo ""

echo -e "${BLUE}3. Flux Framework Version:${NC}"
kubectl exec -n slurm-flux $WORKER_POD -c slurmd -- flux --version
echo ""

echo -e "${BLUE}4. Flux Resources (srun flux start flux resource list):${NC}"
# In converged mode, Flux is ephemeral and started by Slurm.
# We must use 'srun flux start' to initialize a Flux instance within an allocation.
kubectl exec -n slurm-flux $WORKER_POD -c slurmd -- srun flux start flux resource list
echo ""

echo -e "${BLUE}5. Running Flux-in-Slurm Job (srun flux start hostname):${NC}"
kubectl exec -n slurm-flux $WORKER_POD -c slurmd -- srun flux start hostname
echo ""

echo -e "${GREEN}✓ Slurm-Flux verification complete!${NC}"
