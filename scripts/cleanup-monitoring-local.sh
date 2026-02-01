#!/bin/bash
set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

echo -e "${BLUE}🧹 Cleaning up local Monitoring on OrbStack...${NC}"
echo ""

# Ensure we're using OrbStack context
echo -e "${BLUE}Configuring context...${NC}"
kubectl config use-context orbstack >/dev/null

# Uninstall Helm release
if helm status kube-prometheus-stack -n monitoring >/dev/null 2>&1; then
  echo -e "${BLUE}Uninstalling kube-prometheus-stack...${NC}"
  helm uninstall kube-prometheus-stack -n monitoring
  echo -e "${GREEN}✓ Helm release uninstalled${NC}"
else
  echo -e "${YELLOW}Helm release not found, skipping.${NC}"
fi

# Delete namespace
if kubectl get namespace monitoring >/dev/null 2>&1; then
  echo -e "${BLUE}Deleting monitoring namespace...${NC}"
  kubectl delete namespace monitoring --wait=true
  echo -e "${GREEN}✓ Namespace deleted${NC}"
else
  echo -e "${YELLOW}Namespace 'monitoring' not found, skipping.${NC}"
fi

# Cleanup CRDs (Optional)
if [ "$DELETE_CRDS" = true ]; then
  echo -e "${BLUE}Deleting Prometheus CRDs...${NC}"
  kubectl get crds -o name | grep monitoring.coreos.com | xargs -r kubectl delete
  echo -e "${GREEN}✓ CRDs deleted${NC}"
else
  echo ""
  echo -e "${YELLOW}⚠ Prometheus CRDs were NOT deleted.${NC}"
  echo "  To delete them, run: $0 --delete-crds"
  echo "  (Note: This is global and affects all clusters sharing these CRDs if context is wrong, though CRDs are cluster-scoped)"
fi

echo ""
echo -e "${GREEN}✓ Local monitoring cleanup complete!${NC}"
