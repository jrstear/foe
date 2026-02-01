#!/bin/bash
set -e

echo "🧹 Cleaning up Monitoring Stack (Prometheus/Grafana) on EKS..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse args
DELETE_CRDS=false
for arg in "$@"; do
  case $arg in
    --delete-crds)
      DELETE_CRDS=true
      shift
      ;;
  esac
done

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

echo -e "${BLUE}Step 1: Uninstalling Prometheus releases...${NC}"
helm uninstall prometheus -n monitoring --wait || echo "Release 'prometheus' not found."
helm uninstall monitoring -n monitoring --wait || echo "Release 'monitoring' not found."

echo -e "${BLUE}Step 2: Deleting CRDs (Optional)...${NC}"
if [ "$DELETE_CRDS" = true ]; then
    echo -e "${BLUE}Deleting Prometheus CRDs...${NC}"
    kubectl delete crd alertmanagerconfigs.monitoring.coreos.com || true
    kubectl delete crd alertmanagers.monitoring.coreos.com || true
    kubectl delete crd podmonitors.monitoring.coreos.com || true
    kubectl delete crd probes.monitoring.coreos.com || true
    kubectl delete crd prometheuses.monitoring.coreos.com || true
    kubectl delete crd prometheusrules.monitoring.coreos.com || true
    kubectl delete crd servicemonitors.monitoring.coreos.com || true
    kubectl delete crd thanosrulers.monitoring.coreos.com || true
    echo "CRDs deleted."
else
    echo -e "${YELLOW}Skipping CRD deletion. Use --delete-crds to remove them.${NC}"
fi

echo -e "${BLUE}Step 3: Deleting monitoring namespace...${NC}"
kubectl delete namespace monitoring --ignore-not-found=true

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
