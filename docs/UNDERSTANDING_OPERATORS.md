# Understanding Kubernetes Operators and Custom Resources

## What is a MiniCluster?

A **MiniCluster** is a **Custom Resource Definition (CRD)** - a custom Kubernetes object type created by the Flux Operator.

## The Operator Pattern

### Standard Kubernetes Resources
Kubernetes comes with built-in resource types:
- `Pod` - A running container
- `Deployment` - Manages pods
- `Service` - Network access to pods
- `ConfigMap` - Configuration data

### Custom Resources (CRDs)
Operators extend Kubernetes by adding **new resource types**:
- `MiniCluster` - Defined by Flux Operator
- `Certificate` - Defined by cert-manager
- `Ingress` - Defined by ingress controllers

## How It Works

```
┌─────────────────────────────────────────────────────┐
│  You create a MiniCluster (Custom Resource)         │
│  kubectl apply -f minicluster.yaml                   │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  Flux Operator (Controller) watches for             │
│  MiniCluster resources                               │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  Operator creates standard Kubernetes resources:    │
│  - Pods (for Flux brokers)                          │
│  - Services (for networking)                         │
│  - ConfigMaps (for Flux config)                     │
│  - Jobs (for workload execution)                    │
└─────────────────────────────────────────────────────┘
```

## Your Deployment

### What You Created
```yaml
# k8s/minicluster-local.yaml
apiVersion: flux-framework.org/v1alpha2
kind: MiniCluster  # <-- Custom Resource
metadata:
  name: sandia-study-cluster-local
spec:
  size: 1
  # ... configuration
```

### What the Operator Created
```bash
# The MiniCluster resource
kubectl get minicluster
# NAME                         AGE
# sandia-study-cluster-local   15m

# The Pod(s) it created
kubectl get pods
# NAME                                 READY   STATUS
# sandia-study-cluster-local-0-s6l4l   1/1     Running
```

## Why Both Exist

**MiniCluster** (Custom Resource):
- High-level abstraction
- Describes WHAT you want (a Flux cluster)
- Managed by you
- Declarative configuration

**Pod** (Standard Resource):
- Low-level implementation
- HOW it's actually running
- Managed by the Operator
- Created/deleted automatically

## Analogy

Think of it like ordering food:

**MiniCluster** = Your order ("I want a Flux cluster with 2 nodes")  
**Operator** = The kitchen (processes your order)  
**Pods** = The actual food delivered to your table

You interact with the **order** (MiniCluster), but you can also inspect the **food** (Pods) directly.

## Relationship

```
MiniCluster (1)
    │
    ├─── owns ───► Pod (1..N)
    ├─── owns ───► Service (0..N)
    ├─── owns ───► ConfigMap (0..N)
    └─── owns ───► Job (0..N)
```

The Operator ensures:
- If you delete the MiniCluster → Pods are deleted
- If a Pod crashes → Operator recreates it
- If you update MiniCluster → Operator updates Pods

## Viewing the Relationship

**See what the MiniCluster created**:
```bash
kubectl describe minicluster sandia-study-cluster-local
# Look for "Events" section
```

**See what owns a Pod**:
```bash
kubectl get pod sandia-study-cluster-local-0-s6l4l -o yaml | grep -A5 ownerReferences
```

**See all CRDs installed**:
```bash
kubectl get crd
# Look for: miniclusters.flux-framework.org
```

## Why This Matters for Sandia

**Operators are the standard way to run complex applications on Kubernetes**:

- **Flux Operator**: Manages HPC clusters
- **Prometheus Operator**: Manages monitoring
- **Cert-Manager**: Manages TLS certificates
- **ArgoCD**: Manages GitOps deployments

**OpenShift uses Operator Lifecycle Manager (OLM)** to manage operators, which is why the Flux Operator is relevant for Sandia's OpenShift environment.

## Commands Summary

```bash
# Custom Resources (what you manage)
kubectl get minicluster
kubectl describe minicluster sandia-study-cluster-local
kubectl delete minicluster sandia-study-cluster-local

# Standard Resources (what the operator creates)
kubectl get pods
kubectl describe pod sandia-study-cluster-local-0-s6l4l
kubectl logs sandia-study-cluster-local-0-s6l4l

# See the CRD definition
kubectl get crd miniclusters.flux-framework.org -o yaml

# See what the operator is doing
kubectl logs -n operator-system -l app.kubernetes.io/name=flux-operator
```

## Key Insight

**You don't create Pods directly** - you create a MiniCluster, and the Flux Operator creates/manages the Pods for you. This is the power of the Operator pattern: it encodes operational knowledge into code.
