#!/bin/bash
# 🧹 Cleanup Slurm + Flux (Converged) on OrbStack
set -e

echo "🧹 Cleaning up Slinky-Flux on OrbStack..."

kubectl config use-context orbstack

# Delete the Slurm cluster
echo "Uninstalling Slurm-Flux cluster..."
helm uninstall slurm-flux -n slurm-flux || true

# Delete operator
echo "Uninstalling Slinky Operator..."
helm uninstall slurm-operator -n slurm-operator || true
helm uninstall slurm-operator-crds -n slurm-operator || true

# Delete namespaces
echo "Deleting namespaces..."
kubectl delete namespace slurm-flux --wait=false || true
kubectl delete namespace slurm-operator --wait=false || true

echo "✓ Cleanup complete."
