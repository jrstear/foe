# Viewing Flux Graph Model in Logs

## Quick Commands

### See the Resource Graph (R_lite format)
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l | grep "R_lite"
```

**Output**:
```json
{"version": 1, "execution": {
  "R_lite": [{
    "rank": "0",
    "children": {"core": "0-9"}
  }],
  "nodelist": ["sandia-study-cluster-local-0"]
}}
```

### See Fluxion Scheduler Loading the Graph
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l | grep -i "fluxion\|resource graph"
```

**Output**:
```
sched-fluxion-resource.info[0]: version 0.32.0-56-g8671d560
sched-fluxion-resource.debug[0]: resource graph datastore loaded
sched-fluxion-resource.debug[0]: mod_main: resource graph database loaded
```

### See Resource Status Changes
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l | grep "resource status"
```

**Output**:
```
sched-fluxion-resource.debug[0]: resource status changed (rankset=[all] status=DOWN)
sched-fluxion-resource.debug[0]: resource status changed (rankset=[0] status=UP)
```

### See Complete Resource Initialization
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l | grep -A5 -B5 "📦 Resources"
```

**Output**:
```
📦 Resources
flux R encode --hosts=sandia-study-cluster-local-[0] --local
{"version": 1, "execution": {...}}
```

## All Graph-Related Logs

### Complete Graph Initialization Sequence
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l | grep -E "(R_lite|fluxion|resource graph|resource status|populate_resource)"
```

### Pretty-Printed JSON
```bash
kubectl logs sandia-study-cluster-local-0-s6l4l | grep "R_lite" | python3 -m json.tool
```

**Output**:
```json
{
    "version": 1,
    "execution": {
        "R_lite": [
            {
                "rank": "0",
                "children": {
                    "core": "0-9"
                }
            }
        ],
        "starttime": 0.0,
        "expiration": 0.0,
        "nodelist": [
            "sandia-study-cluster-local-0"
        ]
    }
}
```

## Save to File for Analysis

```bash
# Save all logs
kubectl logs sandia-study-cluster-local-0-s6l4l > flux-logs.txt

# Extract just graph-related lines
kubectl logs sandia-study-cluster-local-0-s6l4l | \
  grep -E "(R_lite|fluxion|resource graph|resource status)" > flux-graph.txt

# View the file
cat flux-graph.txt
```

## For EKS (When Deployed)

### See 2-Node Graph
```bash
# Switch to EKS context first
kubectl config use-context <eks-context>

# Get the lead broker pod
POD=$(kubectl get pods -l flux-role=broker,flux-index=0 -o jsonpath='{.items[0].metadata.name}')

# View the resource graph
kubectl logs $POD | grep "R_lite"
```

**Expected output** (2 nodes):
```json
{
  "R_lite": [
    {"rank": "0", "children": {"core": "0-X"}},
    {"rank": "1", "children": {"core": "0-X"}}
  ],
  "nodelist": ["sandia-study-cluster-0", "sandia-study-cluster-1"]
}
```

## Understanding the Output

### R_lite Format
```json
{
  "version": 1,
  "execution": {
    "R_lite": [              // Resource lite format
      {
        "rank": "0",         // Node rank (0-based index)
        "children": {
          "core": "0-9"      // Resources: cores 0-9
        }
      }
    ],
    "nodelist": ["..."],     // List of node hostnames
    "starttime": 0.0,        // When resources become available
    "expiration": 0.0        // When they expire (0 = never)
  }
}
```

### What Each Field Means

- **rank**: Node index in the cluster (0, 1, 2, ...)
- **children**: Resources available on that node
  - `core`: CPU cores
  - `gpu`: GPUs (if present)
  - `socket`: NUMA sockets (if detected)
- **nodelist**: Actual hostnames of nodes
- **starttime/expiration**: Resource availability window

## Interactive Exploration (When Working)

If you get interactive Flux access working:

```bash
# View resource graph
flux resource list

# View in JSON format
flux resource info

# View specific node
flux resource info -s 0

# View resource status
flux resource status
```

## Comparison: Local vs EKS

### Local (1 node)
```bash
kubectl config use-context orbstack
kubectl logs sandia-study-cluster-local-0-s6l4l | grep "R_lite"
```
→ Shows 1 node graph

### EKS (2 nodes)
```bash
kubectl config use-context <eks-context>
kubectl logs <pod-name> | grep "R_lite"
```
→ Shows 2 node graph

## Quick Reference

| What to See | Command |
|-------------|---------|
| Resource graph JSON | `kubectl logs <pod> \| grep "R_lite"` |
| Fluxion loading | `kubectl logs <pod> \| grep fluxion` |
| Resource status | `kubectl logs <pod> \| grep "resource status"` |
| All graph logs | `kubectl logs <pod> \| grep -E "(R_lite\|fluxion\|resource)"` |
| Pretty JSON | `kubectl logs <pod> \| grep "R_lite" \| python3 -m json.tool` |
