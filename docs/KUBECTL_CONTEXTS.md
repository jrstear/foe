# Kubectl Contexts - How kubectl Knows Which Cluster to Use

## The Answer

`kubectl` uses **contexts** stored in `~/.kube/config` to know which cluster to talk to.

## Your Current Setup

```bash
kubectl config get-contexts
# CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
# *         orbstack   orbstack   orbstack
```

The `*` shows **orbstack is active** - that's why `kubectl apply` goes to OrbStack, not EKS.

## What is a Context?

A context combines three things:
1. **Cluster** - Which Kubernetes cluster (URL + certificate)
2. **User** - Authentication credentials
3. **Namespace** - Default namespace (optional)

## Your Current Context

```bash
kubectl config current-context
# orbstack

kubectl config view --minify
# server: https://127.0.0.1:26443  <-- Local OrbStack
```

## When You Deploy to EKS

After running `terraform apply`, you'll run:
```bash
aws eks update-kubeconfig --region us-west-2 --name sandia-hpc --profile personal
```

This **adds a new context** to your config:
```bash
kubectl config get-contexts
# CURRENT   NAME                              CLUSTER                           AUTHINFO
# *         orbstack                          orbstack                          orbstack
#           arn:aws:eks:us-west-2:...:sandia  arn:aws:eks:us-west-2:...:sandia  arn:aws:eks:...
```

## Switching Between Clusters

### Switch to EKS
```bash
kubectl config use-context arn:aws:eks:us-west-2:869054869504:cluster/sandia-hpc
# Switched to context "arn:aws:eks:us-west-2:869054869504:cluster/sandia-hpc"
```

Now `kubectl apply -f k8s/flux-eks.yaml` goes to **EKS**.

### Switch Back to Local
```bash
kubectl config use-context orbstack
# Switched to context "orbstack"
```

Now `kubectl apply -f k8s/flux-orbstack.yaml` goes to **OrbStack**.

## One-Time Override

You can also specify context per-command:
```bash
# Apply to OrbStack
kubectl apply -f k8s/minicluster-local.yaml --context orbstack

# Apply to EKS
kubectl apply -f k8s/minicluster.yaml --context arn:aws:eks:...

# Get pods from OrbStack
kubectl get pods --context orbstack

# Get pods from EKS
kubectl get pods --context arn:aws:eks:...
```

## Viewing Your Config

**See all contexts**:
```bash
kubectl config get-contexts
```

**See current context**:
```bash
kubectl config current-context
```

**See full config**:
```bash
kubectl config view
```

**See only current context details**:
```bash
kubectl config view --minify
```

## Config File Location

All contexts are stored in:
```bash
~/.kube/config
```

You can edit it manually, but it's better to use `kubectl config` commands.

## Useful Aliases

Add to your `~/.zshrc` or `~/.bashrc`:
```bash
# Quick context switching
alias kc='kubectl config use-context'
alias kcc='kubectl config current-context'
alias kcg='kubectl config get-contexts'

# Usage:
# kc orbstack        # Switch to local
# kc <eks-context>   # Switch to EKS
# kcc                # Show current
# kcg                # List all
```

## Safety Tips

**Always check your context before applying**:
```bash
kubectl config current-context
kubectl apply -f k8s/minicluster.yaml
```

**Use different manifest files**:
- `k8s/flux-orbstack.yaml` → OrbStack (1 node)
- `k8s/flux-eks.yaml` → EKS (2 nodes)

This prevents accidentally deploying the wrong config to the wrong cluster.

## Example Workflow

```bash
# 1. Check where you are
kubectl config current-context
# orbstack

# 2. Deploy to local
kubectl apply -f k8s/minicluster-local.yaml
# minicluster.flux-framework.org/sandia-study-cluster-local created

# 3. Switch to EKS (when ready)
kubectl config use-context arn:aws:eks:us-west-2:869054869504:cluster/sandia-hpc

# 4. Deploy to EKS
kubectl apply -f k8s/minicluster.yaml
# minicluster.flux-framework.org/sandia-study-cluster created

# 5. Check EKS pods
kubectl get pods
# sandia-study-cluster-0-xxxxx   1/1     Running
# sandia-study-cluster-1-yyyyy   1/1     Running

# 6. Switch back to local
kubectl config use-context orbstack

# 7. Check local pods
kubectl get pods
# sandia-study-cluster-local-0-s6l4l   1/1     Running
```

## Key Takeaway

**kubectl doesn't know about "OrbStack" vs "EKS"** - it just knows about contexts. The context tells it:
- Where to connect (cluster URL)
- How to authenticate (credentials)
- What namespace to use (default)

You control which cluster by **switching contexts**.
