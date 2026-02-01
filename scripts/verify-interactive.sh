#!/bin/bash
# 🔬 Interactive Verification Script for Flux MiniCluster on EKS
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}1. Getting lead broker pod...${NC}"
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=sandia-study-cluster,job-index=0 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
    echo "Error: Could not find lead broker pod"
    exit 1
fi
echo "Lead broker pod: $POD_NAME"

echo -e "\n${BLUE}2. Getting Flux URI...${NC}"
# Extract URI from logs
FLUX_URI=$(kubectl logs $POD_NAME | grep "Slocal-uri=local://" | sed 's/.*Slocal-uri=local:\/\/\([^ ]*\).*/local:\/\/\1/')

if [ -z "$FLUX_URI" ]; then
    echo "Using default fallback URI..."
    FLUX_URI="local:///mnt/flux/config/run/flux/local"
fi
echo "Flux URI: $FLUX_URI"

echo -e "\n${BLUE}3. Testing interactive parallel job (2 nodes)...${NC}"
echo "Command: flux run -n 2 hostname"
kubectl exec $POD_NAME -- bash -c "export FLUX_URI=$FLUX_URI && flux run -n 2 hostname"

echo -e "\n${BLUE}4. Checking resource list...${NC}"
kubectl exec $POD_NAME -- bash -c "export FLUX_URI=$FLUX_URI && flux resource list"

echo -e "\n${GREEN}✓ Interactive verification complete!${NC}"
echo "You can now run any flux command via:"
echo "kubectl exec -it $POD_NAME -- bash -c 'export FLUX_URI=$FLUX_URI && flux run ...'"
