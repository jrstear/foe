# Local Kubernetes Quick Reference

## Current Deployment Status

**MiniCluster**: `sandia-study-cluster-local`  
**Pod**: `sandia-study-cluster-local-0-s6l4l`  
**Status**: Running ✅  
**Hostname**: `sandia-study-cluster-local-0`

## Useful Commands

### View Pod Status
```bash
kubectl get pods
kubectl get minicluster
kubectl describe minicluster sandia-study-cluster-local
```

### View Logs

**All containers**:
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l --all-containers=true
```

**Init container (setup)**:
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l -c flux-view
```

**Main container (Flux broker)**:
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l -c sandia-study-cluster-local
```

**Follow logs in real-time**:
```bash
kubectl logs -f sandia-study-cluster-local-0-s6l4l
```

### Exec into Pod

**Interactive shell**:
```bash
kubectl exec -it sandia-study-cluster-local-0-s6l4l -- bash
```

**Run single command**:
```bash
kubectl exec sandia-study-cluster-local-0-s6l4l -- hostname
kubectl exec sandia-study-cluster-local-0-s6l4l -- ls -la /mnt/flux
kubectl exec sandia-study-cluster-local-0-s6l4l -- ps aux
```

### Explore Flux Files

**Job archive database**:
```bash
kubectl exec sandia-study-cluster-local-0-s6l4l -- ls -la /mnt/flux/config/var/lib/flux/
```

**Flux configuration**:
```bash
kubectl exec sandia-study-cluster-local-0-s6l4l -- cat /mnt/flux/config/etc/flux/config
```

**Check what's running**:
```bash
kubectl exec sandia-study-cluster-local-0-s6l4l -- ps aux | grep flux
```

## Understanding the Job

The MiniCluster was configured to run:
```yaml
command: |
  flux submit hostname
  flux queue drain
```

This job:
1. Submits `hostname` command to Flux
2. Drains the queue (waits for completion)
3. The output should be in the logs

## Hostname Explained

- **Pod name**: `sandia-study-cluster-local-0-s6l4l` (Kubernetes generated)
- **Hostname inside pod**: `sandia-study-cluster-local-0` (set by Flux Operator)
- **Comes from**: `metadata.name` in `k8s/minicluster-local.yaml`

## Limitations

**Interactive Flux access not working** because:
- Flux broker runs in a separate process
- Socket `/run/flux/local` not accessible from exec sessions
- This is a known limitation for single-node local MiniClusters

**Workaround**: View logs instead of interactive commands.

## Clean Up

**Delete MiniCluster**:
```bash
kubectl delete minicluster sandia-study-cluster-local
```

**Redeploy**:
```bash
kubectl apply -f k8s/minicluster-local.yaml
```

## Switch to EKS Context

```bash
# List contexts
kubectl config get-contexts

# Switch to EKS (when deployed)
kubectl config use-context <eks-context-name>

# Switch back to local
kubectl config use-context orbstack
```
