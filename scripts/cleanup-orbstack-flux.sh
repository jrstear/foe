#!/bin/bash
set -e

echo "🧹 Cleaning up local Flux MiniCluster on OrbStack..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure we're using OrbStack context
kubectl config use-context orbstack

echo -e "${BLUE}Step 1: Deleting MiniCluster...${NC}"
kubectl delete -f k8s/flux-orbstack.yaml --ignore-not-found=true

echo "Waiting for MiniCluster pods to terminate..."
kubectl wait --for=delete pods -l app.kubernetes.io/name=sandia-study-cluster-local --timeout=120s 2>/dev/null || true

echo ""
echo -e "${BLUE}Step 2: Deleting Flux Operator...${NC}"
kubectl delete -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml --ignore-not-found=true

echo "Waiting for operator pods to terminate..."
kubectl wait --for=delete namespace operator-system --timeout=120s 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Local cleanup complete!${NC}"
