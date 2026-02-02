#!/bin/bash
# Submit OSU Micro-Benchmark jobs to EKS Flux Cluster
set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BENCHMARK="bw"
NP=2
CLUSTER="cloud"
WAIT="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --benchmark)
      BENCHMARK="$2"
      shift 2
      ;;
    --np)
      NP="$2"
      shift 2
      ;;
    --cluster)
      CLUSTER="$2"
      shift 2
      ;;
    --context)
      CONTEXT="$2"
      shift 2
      ;;
    --wait)
      WAIT="true"
      shift 1
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--benchmark bw|latency|allreduce] [--np NUM_PROCS] [--cluster cloud] [--context CONTEXT_NAME] [--wait]"
      exit 1
      ;;
  esac
done

if [ -n "$CONTEXT" ]; then
  KUBECTL_ARGS="--context $CONTEXT"
else
  # Auto-detect EKS context if current doesn't look like one
  CURRENT_CTX=$(kubectl config current-context)
  if [[ "$CURRENT_CTX" != *"arn:aws:eks"* ]]; then
    EKS_CTX=$(kubectl config get-contexts -o name | grep "arn:aws:eks" | head -n 1)
    if [ -n "$EKS_CTX" ]; then
      echo -e "${YELLOW}Auto-selecting EKS context: $EKS_CTX${NC}"
      KUBECTL_ARGS="--context $EKS_CTX"
    fi
  fi
fi

echo -e "${BLUE}🚀 Submitting OSU Benchmark Job to Flux (EKS)${NC}"
echo ""
echo "Benchmark: osu_${BENCHMARK}"
echo "MPI Processes: ${NP}"
echo "Cluster: ${CLUSTER}"
echo ""

# EKS MiniCluster name
MINICLUSTER="sandia-study-cluster"

# Get the Flux broker pod (index 0)
echo -e "${BLUE}Finding Flux broker pod...${NC}"
POD_NAME=$(kubectl $KUBECTL_ARGS get pods -l job-name=${MINICLUSTER},job-index=0 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
  echo -e "${YELLOW}⚠ Flux MiniCluster not found or not ready${NC}"
  echo ""
  echo "Please deploy the Flux cluster first:"
  echo "  ./eks/deploy.sh"
  exit 1
fi

echo -e "${GREEN}✓ Found broker pod: ${POD_NAME}${NC}"
echo ""

# Install OSU benchmarks if not already present
# Check if OSU benchmarks are installed on persistent storage
BENCH_DIR="/data/benchmarks/osu-micro-benchmarks-7.4"
if kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "test -f ${BENCH_DIR}/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bw"; then
  echo -e "${GREEN}✓ OSU benchmarks found in persistent storage${NC}"
  # Just ensure system deps are present on all nodes (fast)
  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "
    export FLUX_URI=local:///mnt/flux/config/run/flux/local
    flux exec -r all bash -c 'apt-get update -qq && apt-get install -y -qq libopenmpi-dev'
  " > /dev/null 2>&1
else
  echo -e "${YELLOW}Installing OSU Micro-Benchmarks (System Deps + Compilation)...${NC}"
  
  # 1. Install system dependencies on ALL nodes
  echo "Installing system dependencies..."
  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "
    export FLUX_URI=local:///mnt/flux/config/run/flux/local
    flux exec -r all bash -c '
      apt-get update -qq && \
      apt-get install -y -qq wget build-essential libopenmpi-dev
    '
  "

  # 2. Compile and install to /data on ONE node (Rank 0)
  echo "Compiling benchmarks to ${BENCH_DIR}..."
  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "
    mkdir -p ${BENCH_DIR} && \
    cd /tmp && \
    wget -q https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-7.4.tar.gz && \
    tar -xzf osu-micro-benchmarks-7.4.tar.gz && \
    cd osu-micro-benchmarks-7.4 && \
    ./configure CC=mpicc CXX=mpicxx --prefix=${BENCH_DIR} && \
    make -j4 && \
    make install && \
    cd .. && \
    rm -rf osu-micro-benchmarks-7.4*
  "
  echo -e "${GREEN}✓ OSU benchmarks installed to persistent storage${NC}"
fi

echo ""
# Determine benchmark directory
if [[ "$BENCHMARK" == "bw" || "$BENCHMARK" == "latency" || "$BENCHMARK" == "bibw" ]]; then
  BENCH_TYPE="pt2pt"
else
  BENCH_TYPE="collective"
fi

echo -e "${BLUE}Submitting job to Flux...${NC}"

# Submit the job via flux run (cleaner than mpirun nesting)
JOB_ID=$(kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "
  export FLUX_URI=local:///mnt/flux/config/run/flux/local
  flux submit -n ${NP} /data/benchmarks/osu-micro-benchmarks-7.4/libexec/osu-micro-benchmarks/mpi/${BENCH_TYPE}/osu_${BENCHMARK}
" | tr -d '\r')

echo ""
echo -e "${GREEN}✓ Job submitted! ID: ${JOB_ID}${NC}"
echo ""

if [ "$WAIT" == "true" ]; then
  echo -e "${BLUE}Waiting for job completion and attaching output...${NC}"
  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux job attach ${JOB_ID}"
  echo ""
else
  echo -e "${YELLOW}Tip: Use ./eks/check-benchmark.sh to monitor status${NC}"
  echo ""
  echo "Manual commands:"
  echo "  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c \"export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux jobs\""
  echo "  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c \"export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux job attach ${JOB_ID}\""
fi
