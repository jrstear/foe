#!/bin/bash
set -e

echo "🔍 Checking prerequisites for Flux MiniCluster deployment..."
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MISSING_TOOLS=()

# Check for Homebrew (for M1 Mac)
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗${NC} Homebrew not found"
    echo "  Install from: https://brew.sh"
    MISSING_TOOLS+=("homebrew")
else
    echo -e "${GREEN}✓${NC} Homebrew installed"
fi

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗${NC} AWS CLI not found"
    echo "  Install with: brew install awscli"
    MISSING_TOOLS+=("awscli")
else
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    echo -e "${GREEN}✓${NC} AWS CLI installed ($AWS_VERSION)"
fi

# Check for Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗${NC} Terraform not found"
    echo "  Install with: brew tap hashicorp/tap && brew install hashicorp/tap/terraform"
    MISSING_TOOLS+=("terraform")
else
    TF_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✓${NC} Terraform installed (v$TF_VERSION)"
fi

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗${NC} kubectl not found"
    echo "  Install with: brew install kubectl"
    MISSING_TOOLS+=("kubectl")
else
    KUBECTL_VERSION=$(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✓${NC} kubectl installed ($KUBECTL_VERSION)"
fi

# Check for Helm
if ! command -v helm &> /dev/null; then
    echo -e "${RED}✗${NC} Helm not found"
    echo "  Install with: brew install helm"
    MISSING_TOOLS+=("helm")
else
    HELM_VERSION=$(helm version --short)
    echo -e "${GREEN}✓${NC} Helm installed ($HELM_VERSION)"
fi

echo ""

# Check AWS credentials
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
        echo -e "${GREEN}✓${NC} AWS credentials configured"
        echo "  Account: $AWS_ACCOUNT"
        echo "  Identity: $AWS_USER"
    else
        echo -e "${YELLOW}⚠${NC} AWS credentials not configured"
        echo "  Run: aws configure"
        echo "  You'll need:"
        echo "    - AWS Access Key ID"
        echo "    - AWS Secret Access Key"
        echo "    - Default region (use: us-west-2)"
        MISSING_TOOLS+=("aws-credentials")
    fi
fi

echo ""

# Summary
if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All prerequisites met!${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "✓ Prerequisites met!"
    exit 0
else
    echo -e "${RED}✗ Missing prerequisites:${NC}"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "Please install missing tools and configure AWS credentials before proceeding."
    exit 1
fi
