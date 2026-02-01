#!/bin/bash
# 🚀 Setup script for Slinky (Slurm-on-Kubernetes) dependencies
set -e

echo "🛠 Checking dependencies for Slinky..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Core setup first
./scripts/setup.sh

# Install extra Slinky tools if on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v helm &> /dev/null; then
        echo -e "${YELLOW}Installing Helm via Homebrew...${NC}"
        brew install helm
    fi
    
    if ! command -v skaffold &> /dev/null; then
        echo -e "${YELLOW}Installing Skaffold via Homebrew...${NC}"
        brew install skaffold
    fi
fi

# Install cert-manager (required for Slinky webhooks)
echo ""
echo -e "${BLUE}Installing cert-manager...${NC}"
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.16.2 \
  --set installCRDs=true

echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available deployment/cert-manager-webhook \
    -n cert-manager --timeout=300s

echo -e "${GREEN}✓ Slinky dependencies ready!${NC}"
