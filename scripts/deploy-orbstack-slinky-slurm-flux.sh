#!/bin/bash
# 🚀 Deploy Slurm + Flux (Converged) locally on OrbStack
set -e

echo "🚀 Deploying Slinky/Slurm-Flux (Converged) on OrbStack..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure dependencies are met
echo -e "${BLUE}Step 1: Checking dependencies...${NC}"
./scripts/setup-slinky.sh

# Ensure we're using OrbStack context
echo ""
echo -e "${BLUE}Step 2: Configuring kubectl for OrbStack...${NC}"
kubectl config use-context orbstack

# Install Slinky Operator
echo ""
echo -e "${BLUE}Step 3: Installing Slinky Slurm Operator...${NC}"

HELM_VERSION="1.0.0"

echo "Installing CRDs..."
helm upgrade --install slurm-operator-crds oci://ghcr.io/slinkyproject/charts/slurm-operator-crds \
    --version $HELM_VERSION \
    --namespace slurm-operator --create-namespace

echo "Installing Operator..."
helm upgrade --install slurm-operator oci://ghcr.io/slinkyproject/charts/slurm-operator \
    --version $HELM_VERSION \
    --namespace slurm-operator --create-namespace

# Wait for operator
echo "Waiting for Slinky Operator to be ready..."
kubectl wait --for=condition=Available deployment/slurm-operator \
    -n slurm-operator --timeout=300s

# Deploy Slurm Cluster via Helm
echo ""
echo -e "${BLUE}Step 4: Deploying Slurm-Flux Cluster...${NC}"

# Check for custom image
if ! docker image inspect slurm-flux:local >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: slurm-flux:local not found. Building it now...${NC}"
    docker build -t slurm-flux:local ./docker/slurm-flux/
fi

helm upgrade --install slurm-flux oci://ghcr.io/slinkyproject/charts/slurm \
    --version $HELM_VERSION \
    --namespace slurm-flux --create-namespace \
    -f k8s/values-orbstack-slinky.yaml \
    --set clusters.slurm.name=orbstack-slurm-flux \
    --set nodesets.orbstack-slinky.slurmd.image.repository=slurm-flux \
    --set nodesets.orbstack-slinky.slurmd.image.tag=local

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ OrbStack Slinky-Flux Ready!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "  1. Check cluster status: kubectl get clusters.slinky.slurm.net -A"
echo "  2. Run a Flux-in-Slurm job: ./scripts/verify-orbstack-slinky-slurm-flux.sh"
echo ""
echo "To clean up: ./scripts/cleanup-orbstack-slinky-slurm-flux.sh"
