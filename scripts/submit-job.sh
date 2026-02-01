#!/bin/bash
# Submit a job to Flux via REST API

set -e

# Get the REST API service endpoint
echo "Getting Flux REST API endpoint..."
API_URL=$(kubectl get svc flux-rest-api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):5000

if [ -z "$API_URL" ] || [ "$API_URL" == ":5000" ]; then
    echo "LoadBalancer not ready yet. Using port-forward instead..."
    echo "Run this in another terminal:"
    echo "  kubectl port-forward svc/flux-rest-api 5000:5000"
    echo ""
    API_URL="localhost:5000"
fi

echo "API URL: http://$API_URL"
echo ""

# Submit a job
echo "Submitting job: hostname"
curl -X POST "http://$API_URL/api/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "command": ["hostname"],
    "num_nodes": 2,
    "num_tasks": 2
  }'

echo ""
echo ""
echo "Job submitted! Check status with:"
echo "  curl http://$API_URL/api/jobs"
