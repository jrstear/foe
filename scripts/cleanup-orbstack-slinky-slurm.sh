#!/bin/bash
# 🧹 Cleanup Slurm-on-Kubernetes (Slinky) on OrbStack
set -e

echo "🧹 Cleaning up OrbStack Slinky resources..."
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure we're using OrbStack context
kubectl config use-context orbstack

echo -e "${BLUE}Step 1: Deleting Slurm Cluster...${NC}"
kubectl delete -f k8s/slinky-orbstack.yaml --ignore-not-found=true

echo -e "${BLUE}Step 2: Uninstalling Slinky Operator...${NC}"
helm uninstall slurm-operator -n slurm-operator || true
helm uninstall slurm-operator-crds -n slurm-operator || true

echo ""
echo -e "${GREEN}✓ Local Slinky cleanup complete!${NC}"
