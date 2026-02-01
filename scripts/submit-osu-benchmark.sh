#!/bin/bash
# Submit OSU Micro-Benchmark jobs to persistent Flux MiniCluster
set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BENCHMARK="bw"
NP=2
CLUSTER="local"

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
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--benchmark bw|latency|allreduce] [--np NUM_PROCS] [--cluster local|cloud] [--context CONTEXT_NAME]"
      exit 1
      ;;
  esac
done

if [ -n "$CONTEXT" ]; then
  KUBECTL_ARGS="--context $CONTEXT"
else
  KUBECTL_ARGS=""
fi

echo -e "${BLUE}🚀 Submitting OSU Benchmark Job to Flux${NC}"
echo ""
echo "Benchmark: osu_${BENCHMARK}"
echo "MPI Processes: ${NP}"
echo "Cluster: ${CLUSTER}"
echo ""

# Determine MiniCluster name based on cluster
if [ "$CLUSTER" == "local" ]; then
  MINICLUSTER="sandia-study-cluster-local"
else
  MINICLUSTER="sandia-study-cluster"
fi

# Get the Flux broker pod (index 0)
echo -e "${BLUE}Finding Flux broker pod...${NC}"
POD_NAME=$(kubectl $KUBECTL_ARGS get pods -l job-name=${MINICLUSTER},job-index=0 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
  echo -e "${YELLOW}⚠ Flux MiniCluster not found or not ready${NC}"
  echo ""
  echo "Please deploy the Flux cluster first:"
  if [ "$CLUSTER" == "local" ]; then
    echo "  ./scripts/deploy-orbstack-flux.sh"
  else
    echo "  ./scripts/deploy-eks-flux.sh"
  fi
  exit 1
fi

echo -e "${GREEN}✓ Found broker pod: ${POD_NAME}${NC}"
echo ""

# Install OSU benchmarks if not already present
echo -e "${BLUE}Checking for OSU benchmarks...${NC}"
HAS_OSU=$(kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "ls /usr/local/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bw 2>/dev/null" || echo "")

if [ -z "$HAS_OSU" ]; then
  echo -e "${YELLOW}Installing OSU Micro-Benchmarks...${NC}"
  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "
    apt-get update -qq && \
    apt-get install -y -qq wget build-essential libopenmpi-dev && \
    cd /tmp && \
    wget -q https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-7.4.tar.gz && \
    tar -xzf osu-micro-benchmarks-7.4.tar.gz && \
    cd osu-micro-benchmarks-7.4 && \
    ./configure CC=mpicc CXX=mpicxx --prefix=/usr/local && \
    make -j4 && \
    make install && \
    cd .. && \
    rm -rf osu-micro-benchmarks-7.4*
  "
  echo -e "${GREEN}✓ OSU benchmarks installed${NC}"
else
  echo -e "${GREEN}✓ OSU benchmarks already installed${NC}"
fi

echo ""
# Determine benchmark directory (pt2pt vs collective)
if [[ "$BENCHMARK" == "bw" || "$BENCHMARK" == "latency" || "$BENCHMARK" == "bibw" ]]; then
  BENCH_TYPE="pt2pt"
else
  BENCH_TYPE="collective"
fi

echo -e "${BLUE}Submitting job to Flux...${NC}"

# Submit the job via flux
kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c "
  export FLUX_URI=local:///mnt/flux/config/run/flux/local
  flux submit -n ${NP} sudo -u fluxuser /usr/bin/mpirun -np ${NP} /usr/local/libexec/osu-micro-benchmarks/mpi/${BENCH_TYPE}/osu_${BENCHMARK}
"

echo ""
echo -e "${GREEN}✓ Job submitted!${NC}"
echo ""
echo "To view job status:"
echo "  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c \"export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux jobs\""
echo ""
echo "To view job output:"
echo "  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c \"export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux job attach <JOBID>\""
echo ""
echo "To view all jobs:"
echo "  kubectl $KUBECTL_ARGS exec ${POD_NAME} -- bash -c \"export FLUX_URI=local:///mnt/flux/config/run/flux/local; flux jobs -a\""
