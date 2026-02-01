# Local Development with OrbStack

This guide shows how to run Flux **locally** on your M1 Mac using OrbStack instead of AWS EKS.

> [!WARNING]
> **ARM64 Limitation**: The Flux Operator currently has limited ARM64 support. The operator injects init containers that only have x86_64 images. You have two options:
> 
> 1. **Use Rosetta 2** (automated in deploy-local.sh) - OrbStack can emulate x86_64
> 2. **Build custom ARM64 images** - See "Building ARM64 Images" section below
> 
> For production demos, use the EKS deployment which runs on x86_64 instances.

## Why Use OrbStack?

### Advantages
- ✅ **Free** - No AWS charges
- ✅ **Fast** - Cluster ready in ~30 seconds vs 15 minutes
- ✅ **Lightweight** - Uses ~2GB RAM vs cloud resources
- ✅ **Native M1** - ARM64 optimized for Apple Silicon
- ✅ **Instant iteration** - Test configs quickly without waiting

### When to Use
- **Local (OrbStack)**: Development, testing MiniCluster configs, learning Flux
- **Cloud (EKS)**: Final validation, interview demo, production-like environment

## Setup

### 1. Install OrbStack

```bash
brew install orbstack
```

Or download from [https://orbstack.dev](https://orbstack.dev)

### 2. Verify Installation

```bash
orb version
kubectl config get-contexts
```

You should see an `orbstack` context.

## Quick Start

### Deploy Locally

```bash
./scripts/deploy-orbstack-flux.sh
```

This will:
1. Start OrbStack (if not running)
2. Create/use Kubernetes cluster
3. Deploy Flux Operator
4. Deploy MiniCluster
5. Wait for readiness

**Total time**: ~1-2 minutes (vs 15+ minutes for EKS)

### Verify Deployment

```bash
./scripts/verify-orbstack-flux.sh
```

### Access the Cluster

```bash
# Get lead broker pod
POD_NAME=$(kubectl get pods -l flux-role=broker,flux-index=0 -o jsonpath='{.items[0].metadata.name}')

# Exec into head node
kubectl exec -it $POD_NAME -- bash

# Inside pod: run Flux commands
flux run -n 2 hostname
flux resource list
flux jobs
```

## Switching Between Local and Cloud

### View Available Contexts

```bash
kubectl config get-contexts
```

### Switch to Local (OrbStack)

```bash
kubectl config use-context orbstack
```

### Switch to Cloud (EKS)

```bash
kubectl config use-context <eks-context-name>
# Example: kubectl config use-context arn:aws:eks:us-west-2:869054869504:cluster/sandia-hpc
```

### Check Current Context

```bash
kubectl config current-context
```

## Development Workflow

### Recommended Pattern

```bash
# 1. Develop and test locally
kubectl config use-context orbstack
./scripts/deploy-orbstack-flux.sh
./scripts/verify-orbstack-flux.sh
./scripts/cleanup-orbstack-flux.sh
flux-orbstack.yaml

# 2. Edit MiniCluster config
vim k8s/minicluster.yaml

# 3. Redeploy (fast!)
kubectl delete -f k8s/minicluster.yaml
kubectl apply -f k8s/minicluster.yaml

# 4. Verify changes
./scripts/verify-local.sh

# 5. Once working, validate on EKS
kubectl config use-context <eks-context>
./scripts/deploy.sh
```

## Differences from EKS

### What's the Same
- ✅ Same `k8s/minicluster.yaml` manifest
- ✅ Same Flux Operator
- ✅ Same kubectl commands
- ✅ Same Flux commands inside pods

### What's Different
- **Nodes**: Single node (OrbStack) vs 2 nodes (EKS)
- **Resources**: Limited by your Mac (16GB) vs cloud scaling
- **Networking**: Local only vs internet-accessible
- **Cost**: Free vs ~$0.23/hour

### Adjusting for Single Node

If you want to test on a single node locally, create `k8s/minicluster-local.yaml`:

```yaml
apiVersion: flux-framework.org/v1alpha2
kind: MiniCluster
metadata:
  name: sandia-study-cluster-local
spec:
  size: 1  # Single node for local testing
  tasks: 1
  containers:
    - image: ghcr.io/flux-framework/flux-restful-api:latest
      command: |
        flux submit hostname
        flux queue drain
  interactive: true
  flux:
    logLevel: 7
```

Then deploy with:
```bash
kubectl apply -f k8s/minicluster-local.yaml
```

## Building ARM64 Images (Advanced)

If Rosetta 2 emulation doesn't work or you want native ARM64 performance, you can build custom Flux images.

### Quick Build (Automated)

```bash
./scripts/build-arm64-images.sh
```

This script will:
1. Initialize the flux-operator git submodule
2. Build ARM64 version of flux-view-rocky
3. Tag the image for local use

### Manual Build

#### Prerequisites

```bash
# Install Docker buildx for multi-platform builds
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

### Build Flux View Rocky for ARM64

```bash
# Initialize the flux-operator submodule
git submodule update --init --recursive vendor/flux-operator
cd vendor/flux-operator

# Build ARM64 version of flux-view-rocky
docker buildx build \
  --platform linux/arm64 \
  -t localhost:5000/flux-view-rocky:arm64 \
  -f docker/Dockerfile.view \
  --build-arg tag=9 \
  --load \
  .

# Push to local registry (OrbStack has built-in registry)
docker tag localhost:5000/flux-view-rocky:arm64 localhost:5000/flux-view-rocky:tag-9
docker push localhost:5000/flux-view-rocky:tag-9
```

### Configure MiniCluster to Use Local Images

Create `k8s/minicluster-arm64.yaml`:

```yaml
apiVersion: flux-framework.org/v1alpha2
kind: MiniCluster
metadata:
  name: sandia-study-cluster-arm64
spec:
  size: 1
  tasks: 1
  
  # Override default images with ARM64 builds
  flux:
    container:
      image: localhost:5000/flux-view-rocky:tag-9
  
  containers:
    - image: ghcr.io/flux-framework/flux-restful-api:latest
      command: |
        flux submit hostname
        flux queue drain
  
  interactive: true
  flux:
    logLevel: 7
```

### Deploy with Custom Images

```bash
kubectl apply -f k8s/minicluster-arm64.yaml
```

### Alternative: Use Pre-built ARM64 Images

Some Flux images have ARM64 support. Try these:

```yaml
containers:
  - image: ghcr.io/flux-framework/flux-sched:latest
    # or
  - image: ghcr.io/flux-framework/flux-core:latest
```

Check available platforms:
```bash
docker manifest inspect ghcr.io/flux-framework/flux-core:latest | grep architecture
```

## Cleanup

### Delete MiniCluster Only

```bash
kubectl delete -f k8s/minicluster.yaml
```

### Delete Flux Operator

```bash
kubectl delete -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml
```

### Stop OrbStack

```bash
orb stop
```

### Remove OrbStack Kubernetes

```bash
orb delete k8s
```

## Troubleshooting

### OrbStack Not Starting

```bash
# Check status
orb status

# Restart OrbStack
orb restart

# Check logs
orb logs
```

### Pods Stuck in Pending

```bash
# Check node resources
kubectl top nodes

# Describe pod to see events
kubectl describe pod <pod-name>

# OrbStack may need more resources
# Go to OrbStack settings and increase CPU/RAM
```

### Context Not Found

```bash
# List all contexts
kubectl config get-contexts

# If orbstack context missing, recreate
orb delete k8s
orb create k8s
```

## Performance Tips

### OrbStack Settings
- **CPU**: 4 cores recommended
- **RAM**: 8GB recommended for Flux MiniCluster
- **Disk**: 20GB should be sufficient

### Resource Limits
If pods are OOMKilled, reduce resource requests in `minicluster.yaml`:

```yaml
spec:
  containers:
    - resources:
        requests:
          memory: "512Mi"
          cpu: "500m"
        limits:
          memory: "1Gi"
          cpu: "1000m"
```

## Next Steps

- Test different Flux configurations locally
- Experiment with job scheduling
- Try different container images
- Once satisfied, validate on EKS for interview demo

## Resources

- [OrbStack Documentation](https://docs.orbstack.dev/)
- [Flux Framework Docs](https://flux-framework.readthedocs.io/)
- [Flux Operator Examples](https://github.com/flux-framework/flux-operator/tree/main/examples)
