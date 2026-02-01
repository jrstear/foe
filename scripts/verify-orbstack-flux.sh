#!/bin/bash
set -e

echo "🔬 Verifying local Flux deployment on OrbStack..."
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure we're using OrbStack context
kubectl config use-context orbstack

echo -e "${BLUE}1. Cluster nodes:${NC}"
kubectl get nodes
echo ""

echo -e "${BLUE}2. MiniCluster status:${NC}"
kubectl get minicluster sandia-study-cluster-local
echo ""

echo -e "${BLUE}3. MiniCluster pods:${NC}"
kubectl get pods -l app.kubernetes.io/name=flux-sample
echo ""

echo -e "${BLUE}4. Getting lead broker pod...${NC}"
POD_NAME=$(kubectl get pods -l flux-role=broker,flux-index=0 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
    echo "Trying alternative label selector..."
    POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=flux-sample -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
fi

if [ -z "$POD_NAME" ]; then
    echo "Error: No MiniCluster pods found"
    exit 1
fi

echo "Lead broker pod: $POD_NAME"
echo ""

echo -e "${BLUE}5. Running parallel hostname test...${NC}"
echo "Command: flux run -n 2 hostname"
echo ""

kubectl exec -it $POD_NAME -- flux run -n 2 hostname

echo ""
echo -e "${GREEN}✓ Local verification complete!${NC}"
echo ""
echo "To access the head node interactively:"
echo "  kubectl exec -it $POD_NAME -- bash"
