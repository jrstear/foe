#!/bin/bash
set -e

echo "🧹 Cleaning up Flux MiniCluster resources..."
echo ""

# Set AWS profile
export AWS_PROFILE=personal

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}This will destroy all AWS resources created by Terraform.${NC}"
echo -e "${YELLOW}This action cannot be undone.${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}Step 1: Deleting Flux MiniCluster...${NC}"
kubectl delete -f "$SCRIPT_DIR/flux.yaml" --ignore-not-found=true

echo "Waiting for MiniCluster pods to terminate..."
kubectl wait --for=delete pods -l app.kubernetes.io/name=sandia-study-cluster --timeout=120s 2>/dev/null || true

echo ""
echo "Step 2: Deleting Flux Operator..."
kubectl delete -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml --ignore-not-found=true

echo "Waiting for operator pods to terminate..."
kubectl wait --for=delete namespace operator-system --timeout=120s 2>/dev/null || true

echo ""
echo "Step 3: Destroying Terraform infrastructure..."
cd terraform/eks-flux
terraform destroy -auto-approve

cd ..

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
echo "All AWS resources have been destroyed."
echo "Verify in AWS Console that no resources remain to avoid unexpected charges."
