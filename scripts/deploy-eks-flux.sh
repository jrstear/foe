#!/bin/bash
set -e

echo "🚀 Deploying Flux (Converged) on Amazon EKS..."
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
cd terraform/eks-flux

# Initialize Terraform
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Plan and apply
echo "Planning infrastructure..."
terraform plan -out=tfplan

echo ""
read -p "Apply this plan? (yes/no): " APPLY
if [ "$APPLY" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

echo "Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw region)

cd ..

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
echo -e "${BLUE}Step 4: Deploying Flux Operator...${NC}"
kubectl apply -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml

# Wait for operator to be ready
echo "Waiting for Flux Operator to be ready..."
kubectl wait --for=condition=Available deployment/operator-controller-manager \
    -n operator-system --timeout=300s

echo ""
echo -e "${GREEN}✓ Flux Operator pods:${NC}"
kubectl get pods -n operator-system

echo ""
kubectl apply -f k8s/flux-eks.yaml

# Wait for MiniCluster to be ready
echo "Waiting for MiniCluster to be ready (this may take a few minutes)..."
sleep 10

# Monitor MiniCluster status
for i in {1..30}; do
    STATUS=$(kubectl get minicluster sandia-study-cluster -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [ "$STATUS" == "True" ]; then
        echo -e "${GREEN}✓ MiniCluster is ready!${NC}"
        break
    fi
    echo "Waiting... (attempt $i/30)"
    sleep 10
done

echo ""
echo -e "${GREEN}✓ MiniCluster status:${NC}"
kubectl get minicluster sandia-study-cluster

echo ""
echo -e "${GREEN}✓ MiniCluster pods:${NC}"
kubectl get pods -l app.kubernetes.io/name=flux-sample

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/verify-eks-flux.sh to test the cluster"
echo "  2. Access the head node:"
echo "     POD_NAME=\$(kubectl get pods -l flux-role=broker,flux-index=0 -o jsonpath='{.items[0].metadata.name}')"
echo "     kubectl exec -it \$POD_NAME -- bash"
echo "  3. Inside the pod, run: flux run -n 2 hostname"
echo ""
echo "To clean up: ./scripts/cleanup-eks-flux.sh"
