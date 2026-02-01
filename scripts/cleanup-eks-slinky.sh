#!/bin/bash
# 🧹 Cleanup Slinky/Slurm on Amazon EKS
set -e

echo "🧹 Cleaning up Slinky/Slurm resources..."
echo ""

# Set AWS profile
export AWS_PROFILE=personal

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}This will destroy all AWS resources for slinky-hpc.${NC}"
echo ""
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Switch context to slinky
aws eks update-kubeconfig --region us-west-2 --name slinky-hpc 2>/dev/null || true

echo "Deleting Slinky resources..."
# kubectl delete -f k8s/slinky-cluster.yaml --ignore-not-found=true || true

echo "Destroying Terraform infrastructure..."
cd terraform/eks-slinky
terraform destroy -auto-approve

echo -e "${GREEN}✓ Cleanup complete!${NC}"
