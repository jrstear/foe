#!/bin/bash
set -e

echo "🔨 Setting up ARM64 Flux images for M1 Mac..."
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    echo "OrbStack includes Docker. Make sure OrbStack is running."
    exit 1
fi

echo -e "${GREEN}✓ Docker available${NC}"
echo ""

echo -e "${BLUE}Good news!${NC} ARM64 Flux images already exist!"
echo ""
echo "Available ARM64 images:"
echo "  - ghcr.io/converged-computing/flux-view-rocky:arm-9"
echo "  - ghcr.io/converged-computing/flux-view-ubuntu:arm-jammy"
echo "  - ghcr.io/converged-computing/flux-view-ubuntu:arm-focal"
echo ""

echo -e "${BLUE}Step 1: Pulling ARM64 flux-view-rocky image...${NC}"
docker pull --platform linux/arm64 ghcr.io/converged-computing/flux-view-rocky:arm-9

echo ""
echo -e "${BLUE}Step 2: Tagging for compatibility...${NC}"
# Tag as the version the operator expects
docker tag ghcr.io/converged-computing/flux-view-rocky:arm-9 ghcr.io/converged-computing/flux-view-rocky:tag-9

echo ""
echo -e "${GREEN}✓ ARM64 image ready!${NC}"
echo ""
echo "Image: ghcr.io/converged-computing/flux-view-rocky:tag-9 (ARM64)"
echo ""
echo "Now deploy with:"
echo "  ./scripts/deploy-local.sh"
echo ""
echo -e "${YELLOW}Note:${NC} The MiniCluster will now use the ARM64-compatible image automatically."

echo -e "${GREEN}✓ Done!${NC}"
