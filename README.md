# Flux MiniCluster on Amazon EKS

Deploy a Flux Framework MiniCluster on Amazon EKS to demonstrate hybrid HPC capabilities—bridging cloud infrastructure with HPC workload management.

## Overview

This project demonstrates deploying a production-grade HPC environment on Kubernetes using:
- **Terraform** for infrastructure as code
- **Amazon EKS** for managed Kubernetes
- **Flux Operator** for HPC workload scheduling
- **MiniCluster** for multi-node parallel computing

Perfect for demonstrating hybrid cloud/HPC expertise for positions at national labs like Sandia.

## Quick Start

### Local Development (Fast & Free)
```bash
# Install OrbStack
brew install orbstack

# Deploy locally (< 2- **Cloud (EKS)**: `./scripts/deploy-eks-flux.sh`
- **Local (OrbStack)**: `./scripts/deploy-orbstack-flux.sh`
```

See [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) for details.

### Cloud Deployment (Production-like)
```bash
# Check prerequisites
./scripts/setup.sh

# Deploy to AWS EKS (15-20 minutes)
1. `./scripts/deploy-eks-flux.sh`
2. `./scripts/verify-eks-flux.sh`
3. `./scripts/cleanup-eks-flux.sh`

# Clean up when done
./scripts/cleanup.sh
```

See [docs/SETUP.md](docs/SETUP.md) for details.

## Project Structure

```
foe/
├── terraform/          # EKS cluster infrastructure
│   ├── main.tf        # VPC and EKS configuration
│   ├── variables.tf   # Configurable parameters
│   ├── outputs.tf     # Cluster information
│   ├── provider.tf    # AWS provider setup
│   └── versions.tf    # Terraform version constraints
├── k8s/
│   └── minicluster.yaml  # Flux MiniCluster definition
├── scripts/
│   ├── setup.sh       # Prerequisites check
│   ├── deploy.sh      # AWS EKS deployment
│   ├── deploy-local.sh   # OrbStack local deployment
│   ├── verify.sh      # EKS verification
│   ├── verify-local.sh   # Local verification
│   ├── cleanup.sh     # Resource teardown
│   └── build-arm64-images.sh  # Build ARM64 Flux images
├── vendor/
│   └── flux-operator/ # Git submodule for building images
└── docs/
    ├── SETUP.md       # AWS/EKS setup guide
    ├── LOCAL_DEVELOPMENT.md  # OrbStack local dev guide
    └── INTERVIEW_NOTES.md    # Talking points
```

## What This Demonstrates

### Infrastructure Skills
- ✅ Terraform infrastructure as code
- ✅ AWS VPC and networking
- ✅ EKS cluster management
- ✅ IAM roles and security

### Kubernetes Expertise
- ✅ Custom Resource Definitions (CRDs)
- ✅ Operator pattern
- ✅ Pod lifecycle management
- ✅ kubectl proficiency

### HPC Knowledge
- ✅ Flux Framework scheduler
- ✅ Multi-node parallel jobs
- ✅ MPI-style workloads
- ✅ Resource management

### Hybrid Cloud/HPC
- ✅ Cloud bursting capability
- ✅ GitOps-ready architecture
- ✅ OpenShift compatibility
- ✅ Multi-tenancy support

## Prerequisites

- **AWS Account** with billing configured
- **AWS CLI** installed and configured
- **Terraform** >= 1.0
- **kubectl** for Kubernetes management
- **M1 Mac** compatible (all tools have ARM64 builds)

See [docs/SETUP.md](docs/SETUP.md) for detailed installation instructions.

## Cost Estimate

**~$0.23/hour** while running:
- EKS control plane: $0.10/hour
- 2x t3.medium nodes: $0.08/hour
- NAT Gateway: $0.05/hour

**Always run cleanup script when done!**

## Architecture

```
┌─────────────────────────────────────────┐
│         Amazon EKS Cluster              │
│  ┌───────────────────────────────────┐  │
│  │      Flux Operator                │  │
│  └───────────────────────────────────┘  │
│                  │                       │
│                  ▼                       │
│  ┌───────────────────────────────────┐  │
│  │     MiniCluster (2 nodes)         │  │
│  └───────────────────────────────────┘  │
│                  │                       │
│         ┌────────┴────────┐              │
│         ▼                 ▼              │
│  ┌──────────┐      ┌──────────┐         │
│  │ Broker 0 │      │ Broker 1 │         │
│  │ (Leader) │◄────►│          │         │
│  └──────────┘      └──────────┘         │
│         │                 │              │
│         └────────┬────────┘              │
│                  ▼                       │
│          Flux Scheduler                  │
│      (Distributed Job Queue)             │
└─────────────────────────────────────────┘
```

## Usage Examples

### Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name sandia-hpc --profile personal
```

### Deploy Flux Operator
```bash
kubectl apply -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml
```

### Deploy MiniCluster
```bash
kubectl apply -f k8s/minicluster.yaml
```

### Run Parallel Jobs
```bash
# Get lead broker pod
POD_NAME=$(kubectl get pods -l flux-role=broker,flux-index=0 -o jsonpath='{.items[0].metadata.name}')

# Access head node
kubectl exec -it $POD_NAME -- bash

# Inside pod: run parallel hostname test
flux run -n 2 hostname

# Check Flux resources
flux resource list

# View job queue
flux jobs
```

## Documentation

- **[SETUP.md](docs/SETUP.md)**: Complete setup guide with troubleshooting
- **[INTERVIEW_NOTES.md](docs/INTERVIEW_NOTES.md)**: Talking points for Sandia interview

## Why This Matters for Sandia

Sandia National Labs is building a "Hybrid HPC" platform that bridges:
- **On-premises supercomputers** (traditional HPC)
- **Cloud infrastructure** (AWS, Azure)
- **Container orchestration** (OpenShift/Kubernetes)

This project demonstrates:
1. **Cloud Expertise**: Deploying production EKS clusters
2. **HPC Knowledge**: Using Flux for parallel workloads
3. **Hybrid Architecture**: Bridging both worlds seamlessly
4. **OpenShift Ready**: Flux Operator is OLM-compatible
5. **GitOps Native**: All configs are declarative and version-controlled

## Cleanup

⚠️ **Important**: Always clean up to avoid AWS charges!

```bash
./scripts/cleanup.sh
```

This will:
1. Delete the MiniCluster
2. Remove the Flux Operator
3. Destroy all Terraform resources

Verify in AWS Console that all resources are gone.

## Resources

- [Flux Framework Docs](https://flux-framework.readthedocs.io/)
- [Flux Operator GitHub](https://github.com/flux-framework/flux-operator)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

## License

MIT

## Author

Created for Sandia National Labs interview demonstration.
