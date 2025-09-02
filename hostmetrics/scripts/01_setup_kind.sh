#!/bin/bash

# Setup Kind cluster with 2 nodes
# Simple cluster without local registry for hostmetrics demo

set -e

CLUSTER_NAME="${CLUSTER_NAME:-hostmetrics-demo}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo -e "${GREEN}🔧 Setting up Kind cluster${NC}"
echo "=========================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists kind; then
    echo -e "${RED}❌ Kind is not installed. Please install Kind first.${NC}"
    echo "Visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if Kind cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}ℹ️  Cluster ${CLUSTER_NAME} already exists${NC}"
    echo -n "Do you want to recreate it? (y/n): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting existing cluster...${NC}"
        kind delete cluster --name="${CLUSTER_NAME}"
    else
        echo "Using existing cluster..."
        kubectl config use-context "kind-${CLUSTER_NAME}"
        exit 0
    fi
fi

echo -e "${BLUE}Creating Kind cluster with 2 nodes...${NC}"
kind create cluster --name="${CLUSTER_NAME}" --config="${PROJECT_ROOT}/kind/cluster.yaml"

echo -e "${GREEN}✅ Kind cluster '${CLUSTER_NAME}' created${NC}"

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Display cluster info
echo ""
echo -e "${GREEN}Cluster Information:${NC}"
echo "===================="
echo "Cluster name: ${CLUSTER_NAME}"
echo "Nodes:"
kubectl get nodes
echo ""
echo "Next step: Run ./scripts/02_install_otel.sh"