#!/bin/bash

# Setup Kind cluster for kgateway demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Kind cluster for kgateway demo${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${RED}❌ kind is not installed. Please install it first.${NC}"
    echo "Visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "kgateway-demo"; then
    echo -e "${YELLOW}⚠️  Cluster 'kgateway-demo' already exists.${NC}"
    read -p "Do you want to delete and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting existing cluster...${NC}"
        kind delete cluster --name kgateway-demo
    else
        echo -e "${BLUE}Using existing cluster.${NC}"
        kubectl config use-context kind-kgateway-demo
        exit 0
    fi
fi

echo -e "${BLUE}Creating Kind cluster with ingress support...${NC}"
kind create cluster --config "${PROJECT_ROOT}/kind/cluster.yaml"

echo -e "${BLUE}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo -e "${GREEN}✅ Kind cluster created successfully!${NC}"
echo ""
kubectl get nodes
echo ""
echo "Cluster Info:"
kubectl cluster-info
echo ""
