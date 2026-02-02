#!/bin/bash
# Deploy Prometheus/Grafana monitoring stack on OrbStack
set -e

echo "🚀 Deploying Prometheus/Grafana on OrbStack..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure we're using OrbStack context
echo -e "${BLUE}Step 1: Configuring kubectl for OrbStack...${NC}"
kubectl config use-context orbstack

# Add Prometheus Helm repo
echo ""
echo -e "${BLUE}Step 2: Adding Prometheus Helm repository...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
echo ""
echo -e "${BLUE}Step 3: Installing kube-prometheus-stack...${NC}"
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    -f orbstack/monitoring-values.yaml \
    --wait --timeout 10m

# Wait for Prometheus to be ready
echo ""
echo -e "${BLUE}Step 4: Waiting for Prometheus to be ready...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus \
    -n monitoring --timeout=300s

# Wait for Grafana to be ready
echo ""
echo -e "${BLUE}Step 5: Waiting for Grafana to be ready...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana \
    -n monitoring --timeout=300s

# Get service info
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Monitoring Stack Deployed!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80"
echo "  Then open: http://localhost:3001"
echo "  Login: admin / prom-operator"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "View pods:"
echo "  kubectl get pods -n monitoring"
echo ""
echo "To clean up: helm uninstall monitoring -n monitoring"
