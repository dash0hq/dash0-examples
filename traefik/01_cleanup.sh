#!/bin/bash

# Traefik Demo - Cleanup Script
# This script removes all resources created by 00_run.sh

set -e

CLUSTER_NAME="traefik-demo"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Traefik Demo - Cleanup Script${NC}"
echo "====================================="

echo -e "\n${RED}⚠️  This will delete all resources created by the demo.${NC}"
echo -n "Are you sure you want to continue? (y/n): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete Kubernetes resources
echo -e "\n${YELLOW}Deleting Kubernetes resources...${NC}"
kubectl delete namespace demo --ignore-not-found=true --wait=false
kubectl delete namespace traefik --ignore-not-found=true --wait=false
kubectl delete namespace opentelemetry --ignore-not-found=true --wait=false

# Delete Kind cluster
echo -e "\n${YELLOW}Deleting Kind cluster...${NC}"
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    kind delete cluster --name="${CLUSTER_NAME}"
    echo -e "${GREEN}✅ Kind cluster deleted${NC}"
else
    echo "Cluster ${CLUSTER_NAME} not found"
fi

echo -e "\n${GREEN}✅ Cleanup complete!${NC}"
echo "All demo resources have been removed."