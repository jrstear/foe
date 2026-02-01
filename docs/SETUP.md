# Flux-on-Kubernetes (Converged) - Setup Guide

This guide walks you through deploying a Flux Framework MiniCluster on Amazon EKS to demonstrate hybrid HPC capabilities.

## Prerequisites

### Required Tools
- **Homebrew** (for M1 Mac): [https://brew.sh](https://brew.sh)
- **AWS CLI**: `brew install awscli`
- **Terraform**: `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
- **kubectl**: `brew install kubectl`

### AWS Account Setup

1. **Create AWS Account** (if needed):
   - Go to [https://aws.amazon.com](https://aws.amazon.com)
   - Click "Create an AWS Account"
   - Follow the registration process

2. **Create IAM User** (recommended for security):
   ```bash
   # In AWS Console:
   # 1. Go to IAM → Users → Add User
   # 2. Enable "Programmatic access"
   # 3. Attach policy: AdministratorAccess (for demo)
   # 4. Save Access Key ID and Secret Access Key
   ```

3. **Configure AWS CLI**:
   ```bash
   aws configure
   # AWS Access Key ID: <your-access-key>
   # AWS Secret Access Key: <your-secret-key>
   # Default region name: us-west-2
   # Default output format: json
   ```

4. **Verify Configuration**:
   ```bash
   aws sts get-caller-identity --profile personal
   ```

### Set Up Billing Alerts

⚠️ **Important**: Set up billing alerts to avoid unexpected charges!

1. Go to AWS Console → Billing → Billing Preferences
2. Enable "Receive Billing Alerts"
3. Go to CloudWatch → Alarms → Create Alarm
4. Set threshold (e.g., $10)
5. Add your email for notifications

## Quick Start

### 1. Check Prerequisites
```bash
./scripts/setup.sh
```

This will verify all required tools and AWS credentials are configured.

### 2. Deploy Infrastructure

**Option A: Automated Deployment**
```bash
./scripts/deploy-eks-flux.sh
```

**Option B: Manual Step-by-Step**
```bash
# Initialize Terraform
cd terraform
terraform init

# Review the plan
terraform plan

# Apply configuration
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name sandia-hpc --profile personal

# Deploy Flux Operator
kubectl apply -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml

# Wait for operator to be ready
kubectl wait --for=condition=Available deployment/operator-controller-manager \
    -n operator-system --timeout=300s

# Deploy MiniCluster
cd ..
kubectl apply -f k8s/flux-eks.yaml

# Wait for MiniCluster to be ready
kubectl get minicluster -w
```

### 3. Verify Deployment
```bash
./scripts/verify-eks-flux.sh
```

### 4. Interact with the Cluster

Get the lead broker pod:
```bash
POD_NAME=$(kubectl get pods -l flux-role=broker,flux-index=0 -o jsonpath='{.items[0].metadata.name}')
```

Access the head node:
```bash
kubectl exec -it $POD_NAME -- bash
```

Inside the pod, run parallel jobs:
```bash
# Run hostname on 2 nodes
flux run -n 2 hostname

# Check Flux status
flux resource list

# View job queue
flux jobs
```

## Cost Estimates

**Hourly Costs** (us-west-2):
- EKS Control Plane: ~$0.10/hour
- 2x t3.medium instances: ~$0.0416/hour each
- NAT Gateway: ~$0.045/hour
- **Total**: ~$0.23/hour

**For a 2-hour demo**: ~$0.50

## Cleanup

⚠️ **Always clean up resources when done to avoid charges!**

```bash
./scripts/cleanup-eks-flux.sh
```

Or manually:
```bash
# Delete MiniCluster
kubectl delete -f k8s/flux-eks.yaml

# Delete Flux Operator
kubectl delete -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml

# Destroy Terraform infrastructure
cd terraform
terraform destroy
```

Verify in AWS Console that all resources are deleted:
- EC2 → Instances (should be empty)
- EKS → Clusters (should be empty)
- VPC → Your VPCs (sandia-hpc-lab-vpc should be gone)

## Troubleshooting

### Terraform Issues

**Error: "No valid credential sources found"**
```bash
# Reconfigure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

**Error: "Insufficient capacity"**
```bash
# Try different instance type or region
# Edit terraform/variables.tf:
variable "node_instance_type" {
  default = "t3.small"  # or t3a.medium
}
```

### Kubernetes Issues

**Pods stuck in Pending**
```bash
# Check node status
kubectl get nodes

# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes
```

**Cannot connect to cluster**
```bash
# Reconfigure kubectl
aws eks update-kubeconfig --region us-west-2 --name sandia-hpc-lab

# Test connection
kubectl get nodes
```

### Flux Operator Issues

**Operator not starting**
```bash
# Check operator logs
kubectl logs -n operator-system -l app.kubernetes.io/name=flux-operator

# Reinstall operator
kubectl delete -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml
kubectl apply -f https://raw.githubusercontent.com/flux-framework/flux-operator/main/examples/dist/flux-operator.yaml
```

**MiniCluster not ready**
```bash
# Check MiniCluster status
kubectl describe minicluster sandia-study-cluster

# Check pod logs
kubectl logs -l app.kubernetes.io/name=flux-sample
```

## Next Steps

- Review [INTERVIEW_NOTES.md](INTERVIEW_NOTES.md) for talking points
- Experiment with different Flux commands
- Try running actual LAMMPS simulations
- Explore Flux job scheduling features

## Resources

- [Flux Framework Documentation](https://flux-framework.readthedocs.io/)
- [Flux Operator GitHub](https://github.com/flux-framework/flux-operator)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
