#!/bin/bash
# 🚀 Deploy Slurm-on-Kubernetes (Slinky) on Amazon EKS
set -e

echo "🚀 Deploying Slinky/Slurm on Amazon EKS..."
echo ""

# Set AWS profile
export AWS_PROFILE=personal

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check prerequisites
echo -e "${BLUE}Step 1: Checking prerequisites...${NC}"
./scripts/setup.sh || exit 1

echo ""
echo -e "${BLUE}Step 2: Deploying Terraform infrastructure...${NC}"
cd terraform/eks-slinky

# Initialize Terraform
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Plan and apply
echo "Planning infrastructure for Slinky..."
terraform apply -auto-approve

# Get outputs
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw region)

cd ../..

echo ""
echo -e "${BLUE}Step 3: Configuring kubectl...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Wait for nodes to be ready
echo "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo ""
echo -e "${GREEN}✓ Cluster nodes ready:${NC}"
kubectl get nodes

echo ""
echo -e "${BLUE}Step 4: Deploying Slinky (Slurm) Operator...${NC}"
# Note: Slinky installation typically involves helm or custom manifests
# For now, we'll use a placeholder apply command or direct research outcome
echo "Installing Slinky Operator (Placeholder)..."
# kubectl apply -f https://raw.githubusercontent.com/schedmd/slinky/main/deploy/operator.yaml

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Slinky Infrastructure Ready!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "  1. Research/Deploy Slurm cluster manifests (minicluster-slinky.yaml)"
echo "  2. Run Slurm jobs via sbatch/srun"
echo ""
echo "To clean up: ./scripts/cleanup-eks-slinky.sh"
