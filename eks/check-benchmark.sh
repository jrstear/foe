#!/bin/bash
set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLUSTER="cloud"
MINICLUSTER="sandia-study-cluster"
# Use current context or optional override
KUBECTL_ARGS=""

# Auto-detect EKS context if current doesn't look like one
CURRENT_CTX=$(kubectl config current-context)
if [[ "$CURRENT_CTX" != *"arn:aws:eks"* ]]; then
  EKS_CTX=$(kubectl config get-contexts -o name | grep "arn:aws:eks" | head -n 1)
  if [ -n "$EKS_CTX" ]; then
    echo -e "${YELLOW}Auto-selecting EKS context: $EKS_CTX${NC}"
    KUBECTL_ARGS="--context $EKS_CTX"
  fi
fi

echo -e "${BLUE}🔍 Checking Flux Benchmark Status (EKS)...${NC}"
echo ""

# Find broker pod
POD_NAME=$(kubectl $KUBECTL_ARGS get pods -l job-name=${MINICLUSTER},job-index=0 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
  echo -e "${YELLOW}⚠ Flux MiniCluster pod not found in current context.${NC}"
  echo "Ensure you are connected to the EKS cluster."
  exit 1
fi

# List recent jobs
echo -e "${BLUE}Recent Flux Jobs:${NC}"
kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux jobs -a | head -n 10"
echo ""

# Get the LATEST job (first valid line with an ID starting with ƒ)
TOP_JOB_LINE=$(kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux jobs -a" 2>/dev/null | grep "ƒ" | head -n 1)

if [ -z "$TOP_JOB_LINE" ]; then
  echo "No jobs found."
  exit 0
fi

LATEST_JOB=$(echo "$TOP_JOB_LINE" | awk '{print $1}')
JOB_NAME=$(echo "$TOP_JOB_LINE" | awk '{print $3}')
JOB_STATUS=$(echo "$TOP_JOB_LINE" | awk '{print $4}')

echo -e "Latest Job: ${GREEN}${LATEST_JOB}${NC} (${JOB_NAME})"
echo -e "Status: ${YELLOW}${JOB_STATUS}${NC}"
echo ""

if [[ "$JOB_STATUS" == "CD" || "$JOB_STATUS" == "F" ]]; then
  echo -e "${GREEN}Job is complete. Attaching output...${NC}"
  echo "----------------------------------------"
  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux job attach ${LATEST_JOB}"
  echo "----------------------------------------"
elif [[ "$JOB_STATUS" == "R" || "$JOB_STATUS" == "RUN" ]]; then
  echo -e "${YELLOW}Job is still running.${NC}"
  echo "You can watch it live with:"
  echo "  kubectl exec ${POD_NAME} -- bash -c \"export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux job attach ${LATEST_JOB}\""
else
  echo "Job state is ${JOB_STATUS}. Waiting..."
fi
