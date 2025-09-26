#!/bin/bash

# Script to set up Kind cluster with ingress support for Emissary-ingress demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="emissary-demo"

echo -e "${BLUE}🎯 Setting up Kind cluster: ${CLUSTER_NAME}${NC}"

# Check if cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}⚠️  Cluster ${CLUSTER_NAME} already exists${NC}"
    echo -n "Do you want to delete and recreate it? (y/n): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🗑️  Deleting existing cluster${NC}"
        kind delete cluster --name="${CLUSTER_NAME}"
    else
        echo -e "${GREEN}✅ Using existing cluster${NC}"
        exit 0
    fi
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

echo -e "${BLUE}📋 Creating cluster with config from: ${PROJECT_DIR}/kind/cluster.yaml${NC}"

# Create cluster
kind create cluster --name="${CLUSTER_NAME}" --config="${PROJECT_DIR}/kind/cluster.yaml"

# Wait for cluster to be ready
echo -e "${BLUE}⏳ Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Display cluster info
echo ""
echo -e "${GREEN}✅ Cluster created successfully!${NC}"
echo ""
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
echo ""
kubectl get nodes

echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  Run: ./scripts/02_install_otel.sh"