#!/bin/bash
set -e

echo "🚀 Deploying Flux (Converged) locally with OrbStack..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Check if OrbStack is installed
if ! command -v orb &> /dev/null; then
    echo -e "${RED}✗ OrbStack not found${NC}"
    echo ""
    echo "Install OrbStack:"
    echo "  brew install orbstack"
    echo ""
    echo "Or download from: https://orbstack.dev"
    exit 1
fi

echo -e "${GREEN}✓ OrbStack installed${NC}"
echo ""

# Check and enable Rosetta 2 for x86_64 emulation
echo -e "${BLUE}Checking Rosetta 2 configuration...${NC}"
ROSETTA_ENABLED=$(orb config get rosetta 2>/dev/null | grep "rosetta: true" || echo "false")
if [[ "$ROSETTA_ENABLED" == "false" ]]; then
    echo -e "${YELLOW}⚠ Rosetta 2 not enabled. Enabling for x86_64 container support...${NC}"
    orb config set rosetta true
    echo -e "${YELLOW}Note: OrbStack needs restart. Run 'orb stop' then 'orb start'${NC}"
    echo ""
    read -p "Restart OrbStack now? (yes/no): " RESTART
    if [ "$RESTART" == "yes" ]; then
        orb stop
        sleep 3
        orb start
        sleep 5
    else
        echo "Please restart OrbStack manually before continuing."
        exit 1
    fi
fi
echo -e "${GREEN}✓ Rosetta 2 enabled${NC}"
echo ""

echo -e "${YELLOW}⚠ ARM64 Limitation:${NC}"
echo "  Flux Operator has limited ARM64 support. Using Rosetta 2 for x86_64 emulation."
echo "  If pods fail with ImagePullBackOff, see docs/LOCAL_DEVELOPMENT.md for alternatives."
echo ""

# Check if OrbStack is running
if ! orb status &> /dev/null; then
    echo -e "${YELLOW}Starting OrbStack...${NC}"
    orb start
    sleep 5
fi

echo -e "${BLUE}Step 1: Configuring kubectl for OrbStack...${NC}"
# Switch to OrbStack context
kubectl config use-context orbstack 2>/dev/null || {
    echo -e "${YELLOW}Creating OrbStack Kubernetes cluster...${NC}"
    orb create k8s
    sleep 10
    kubectl config use-context orbstack
}

echo ""
echo -e "${GREEN}✓ Kubernetes cluster ready:${NC}"
kubectl get nodes

echo ""
echo -e "${BLUE}Step 2: Deploying Flux Operator...${NC}"

# Check if operator is already installed
if kubectl get namespace operator-system &> /dev/null; then
    echo -e "${YELLOW}Flux Operator already installed, skipping...${NC}"
else
    kubectl apply -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml
    
    echo "Waiting for Flux Operator to be ready..."
    kubectl wait --for=condition=Available deployment/operator-controller-manager \
        -n operator-system --timeout=300s
fi

echo ""
echo -e "${GREEN}✓ Flux Operator pods:${NC}"
kubectl get pods -n operator-system

echo ""
echo -e "${BLUE}Step 3: Deploying MiniCluster (ARM64-compatible)...${NC}"

# Delete existing MiniCluster if present
kubectl delete minicluster sandia-study-cluster --ignore-not-found=true
kubectl delete minicluster sandia-study-cluster-local --ignore-not-found=true
sleep 2

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Deploy ARM64-compatible Flux (single node for local)
kubectl apply -f "$SCRIPT_DIR/flux.yaml"

echo "Waiting for MiniCluster to be ready..."
sleep 5

# Monitor MiniCluster status
for i in {1..20}; do
    STATUS=$(kubectl get minicluster sandia-study-cluster-local -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [ "$STATUS" == "True" ]; then
        echo -e "${GREEN}✓ MiniCluster is ready!${NC}"
        break
    fi
    echo "Waiting... (attempt $i/20)"
    sleep 5
done

echo ""
echo -e "${GREEN}✓ MiniCluster status:${NC}"
kubectl get minicluster sandia-study-cluster-local

echo ""
echo -e "${GREEN}✓ MiniCluster pods:${NC}"
kubectl get pods -l app.kubernetes.io/name=flux-sample

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Local deployment complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "  1. Run ./orbstack/verify.sh to test the cluster"
echo "  2. Access the head node:"
echo "     POD_NAME=\$(kubectl get pods -l flux-role=broker,flux-index=0 -o jsonpath='{.items[0].metadata.name}')"
echo "     kubectl exec -it \$POD_NAME -- bash"
echo "  3. Inside the pod, run: flux run -n 2 hostname"
echo ""
echo "To switch back to AWS EKS:"
echo "  kubectl config use-context <eks-context-name>"
echo ""
echo "To clean up local cluster:"
echo "  ./orbstack/cleanup.sh"
