#!/bin/bash
set -e

echo "🚀 Deploying Prometheus to EKS..."
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration
CLUSTER_NAME="sandia-hpc"
REGION="us-west-2"
NAMESPACE="monitoring"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure correct context
echo -e "${BLUE}1. Configuring kubectl context...${NC}"
export AWS_PROFILE=personal
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Create namespace
echo -e "${BLUE}2. Ensuring namespace exists...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repo
echo -e "${BLUE}3. Updating Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install/Upgrade
echo -e "${BLUE}4. Deploying kube-prometheus-stack...${NC}"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --values "$SCRIPT_DIR/monitoring-values.yaml" \
  --wait \
  --timeout 10m

echo ""
echo -e "${BLUE}5. Waiting for LoadBalancer IP...${NC}"
echo "This may take a minute..."

EXTERNAL_IP=""
count=0
while [ -z "$EXTERNAL_IP" ] && [ $count -lt 30 ]; do
    EXTERNAL_IP=$(kubectl get svc -n $NAMESPACE prometheus-kube-prometheus-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -z "$EXTERNAL_IP" ]; then
        # Try IP if hostname is empty (classic LB vs NLB)
        EXTERNAL_IP=$(kubectl get svc -n $NAMESPACE prometheus-kube-prometheus-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    if [ -z "$EXTERNAL_IP" ]; then
        echo "Waiting for LoadBalancer... ($count/30)"
        sleep 10
        count=$((count + 1))
    fi
done

if [ -z "$EXTERNAL_IP" ]; then
    echo "⚠️  Timed out waiting for LoadBalancer IP."
    echo "Check status with: kubectl get svc -n $NAMESPACE"
else
    echo ""
    echo -e "${GREEN}✓ Prometheus deployed successfully!${NC}"
    echo "------------------------------------------------"
    echo "URL: http://$EXTERNAL_IP:9090"
    echo "------------------------------------------------"
    echo ""
    echo "Next steps:"
    echo "1. Verify connectivity: curl http://$EXTERNAL_IP:9090/-/healthy"
    echo "2. Add this URL as a Datasource in your local Grafana"
fi
