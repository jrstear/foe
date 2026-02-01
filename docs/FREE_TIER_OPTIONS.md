# AWS Free Tier and Instance Type Options

## The Issue

Your EKS deployment failed because `t3.medium` is not free-tier eligible. AWS Free Tier only includes `t2.micro` instances.

> [!IMPORTANT]
> **EKS Control Plane is NOT Free Tier**: The EKS control plane costs **$0.10/hour** regardless of your AWS account type. Free tier only applies to EC2 instances (t2.micro). 
> 
> **Bottom line**: You need a paid AWS account to use EKS, even with free-tier EC2 instances.

## Your Options

> [!WARNING]
> **ALL options below require a paid AWS account** because the EKS control plane ($0.10/hour) is NOT free tier eligible. The "free tier" designation only applies to the EC2 instances themselves.

### Option 1: Use t2.micro (Free Tier EC2) - **Updated Default**
```hcl
# terraform/variables.tf already updated to:
variable "node_instance_type" {
  default = "t2.micro"  # Free tier eligible EC2
}
```

**Specs**: 1 vCPU, 1GB RAM  
**Cost**: $0.10/hour (EKS control plane only, EC2 is free)  
**Limitation**: May be too small for Flux MiniCluster  
**Requires**: Paid AWS account (for EKS control plane)

### Option 2: Use t3a.small (Cheapest Non-Free)
```bash
# Override when applying:
terraform apply -var="node_instance_type=t3a.small"
```

**Specs**: 2 vCPU, 2GB RAM  
**Cost**: ~$0.0188/hour (~$0.04/hour for 2 nodes)  
**Recommended**: Better for Flux workloads

### Option 3: Use t3a.medium (Original Plan)
```bash
terraform apply -var="node_instance_type=t3a.medium"
```

**Specs**: 2 vCPU, 4GB RAM  
**Cost**: ~$0.0376/hour (~$0.08/hour for 2 nodes)  
**Best**: Comfortable for Flux MiniCluster

### Option 4: Upgrade to Non-Free Account

If you want to use the original `t3.medium`:
1. Add payment method to AWS account
2. Account automatically becomes non-free tier
3. Use original configuration

## Recommendation

**Bottom Line**: Since you need a paid AWS account for ANY EKS deployment (due to the control plane cost), don't worry about "free tier" instance types. Just pick the best instance for the job.

**For this demo**: Use **t3a.small** or **t3a.medium**
- Good performance for Flux
- Minimal cost difference (~$0.04-0.08/hour for EC2)
- Total cost still low (~$0.14-0.18/hour including EKS)

```bash
cd terraform
terraform apply -var="node_instance_type=t3a.small"  # Recommended
# or
terraform apply -var="node_instance_type=t3a.medium"  # More comfortable
```

## Next Steps

1. **Clean up failed resources**:
   ```bash
   cd terraform
   terraform destroy  # Remove failed deployment
   ```

2. **Redeploy with new instance type**:
   ```bash
   # Option A: Use t2.micro (free but small)
   terraform apply
   
   # Option B: Use t3a.small (recommended, ~$0.04/hour)
   terraform apply -var="node_instance_type=t3a.small"
   
   # Option C: Use t3a.medium (original plan, ~$0.08/hour)
   terraform apply -var="node_instance_type=t3a.medium"
   ```

## Cost Comparison (2 nodes, 2 hours)

| Instance Type | EC2/hour | EKS Control Plane | Total/hour | 2-Hour Demo | Free Tier EC2 |
|---------------|----------|-------------------|------------|-------------|---------------|
| t2.micro      | Free     | $0.10             | **$0.10**  | **$0.20**   | ✅ Yes        |
| t3a.small     | $0.04    | $0.10             | **$0.14**  | **$0.28**   | ❌ No         |
| t3a.medium    | $0.08    | $0.10             | **$0.18**  | **$0.36**   | ❌ No         |
| t3.medium     | $0.08    | $0.10             | **$0.18**  | **$0.36**   | ❌ No         |

**Key Insight**: Even with free-tier t2.micro instances, you still pay $0.10/hour for the EKS control plane.

## Alternative: Use OrbStack Locally (Truly Free)

Since EKS requires a paid account anyway, consider:

1. **Test locally first** with OrbStack (completely free)
   ```bash
   ./scripts/build-arm64-images.sh  # Get ARM64 images
   ./scripts/deploy-local.sh         # Deploy locally
   ```

2. **Then deploy to EKS** for the interview demo
   - Add payment method to AWS account
   - Use t3a.small or t3a.medium for better performance
   - Total cost: ~$0.14-0.18/hour
