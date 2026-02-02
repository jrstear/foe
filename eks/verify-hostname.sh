#!/bin/bash
set -e

echo "🔬 Verifying EKS Flux deployment..."
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Auto-detect EKS context if not explicitly likely correct
CURRENT_CTX=$(kubectl config current-context)
if [[ "$CURRENT_CTX" != *"arn:aws:eks"* ]]; then
  echo -e "${YELLOW}Current context '$CURRENT_CTX' does not look like an EKS cluster.${NC}"
  # Try to find an EKS context
  EKS_CTX=$(kubectl config get-contexts -o name | grep "arn:aws:eks" | head -n 1)
  if [ -n "$EKS_CTX" ]; then
    echo -e "${GREEN}Switching to detected EKS context: $EKS_CTX${NC}"
    kubectl config use-context "$EKS_CTX"
  else
    echo -e "${YELLOW}Warning: Proceeding with '$CURRENT_CTX'. If this fails, set usage context manually.${NC}"
  fi
fi

echo -e "Using Context: ${GREEN}$(kubectl config current-context)${NC}"
echo ""

echo -e "${BLUE}1. Cluster nodes:${NC}"
kubectl get nodes
echo ""

echo -e "${BLUE}2. MiniCluster status:${NC}"
kubectl get minicluster sandia-study-cluster
echo ""

echo -e "${BLUE}3. MiniCluster pods:${NC}"
kubectl get pods -l job-name=sandia-study-cluster
echo ""

echo -e "${BLUE}4. Getting lead broker pod...${NC}"
POD_NAME=$(kubectl get pods -l job-name=sandia-study-cluster,job-index=0 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
    echo "Error: No MiniCluster pods found"
    exit 1
fi

echo "Lead broker pod: $POD_NAME"
echo ""

echo -e "${BLUE}5. Running parallel hostname test...${NC}"
echo "Command: flux run -n 2 hostname"
echo ""

kubectl exec -it $POD_NAME -- bash -c "export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux run -n 2 hostname"

echo ""
echo -e "${GREEN}✓ Hostname verification complete!${NC}"
echo ""
echo "To access the head node interactively:"
echo "  kubectl exec -it $POD_NAME -- bash"
