#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="sandia-study-cluster"
NAMESPACE="default"

# Find the broker pod (rank 0)
echo "🔍 Finding Flux broker pod..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l job-name=$CLUSTER_NAME,job-index=0 -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
  echo "❌ Broker pod not found!"
  exit 1
fi

echo "✅ Found pod: $POD_NAME"

# Startup command (Idempotent-ish: check if running first?)
# We use nohup to keep it running in background
echo "🚀 Starting Flux Metrics Exporter on port 8080..."

# Copy exporter script to pod
kubectl cp eks/flux_exporter.py $NAMESPACE/$POD_NAME:/code/flux_exporter.py

kubectl exec -n $NAMESPACE $POD_NAME -- bash -c "
  # Basic check to see if already running
  if pgrep -f "flux_exporter.py" > /dev/null; then
    echo '⚠️  Exporter already running. Skipping.'
    exit 0
  fi

  export PYTHONPATH=/code
  export FLUX_URI=local:///mnt/flux/config/run/flux/local
  export HOST=0.0.0.0
  export PORT=8080
  
  cd /code
  
  echo '📦 Setting up Environment...'
  if ! command -v pip3 &> /dev/null; then
      apt-get update -qq && apt-get install -y -qq python3-pip
  fi
  
  pip3 install -q prometheus_client

  echo '🔥 Starting Flux Exporter...'
  # Copy content here or assume it's mounted? 
  # We will cat it into place for robustness from this script logic if we were running it locally, 
  # but here we are generating a script to RUN on the mac.
  # So the mac script should COPY the file then EXEC.
  
  nohup python3 /code/flux_exporter.py > /tmp/exporter.log 2>&1 &
"

echo "✅ Exporter started. Logs at /tmp/exporter.log inside pod."
echo "   Test with: kubectl exec $POD_NAME -- curl -s localhost:8080/metrics | head"

