#!/bin/bash

# Dapr Todo Demo - Cleanup Script
# This script removes all resources created by 00_run.sh

set -e

CLUSTER_NAME="dapr-demo"
REGISTRY_NAME="kind-registry"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Dapr Todo Demo - Cleanup Script${NC}"
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
kubectl delete namespace dapr-demo --ignore-not-found=true --wait=false

# Delete Kind cluster
echo -e "\n${YELLOW}Deleting Kind cluster...${NC}"
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    kind delete cluster --name="${CLUSTER_NAME}"
    echo -e "${GREEN}✅ Kind cluster deleted${NC}"
else
    echo "Cluster ${CLUSTER_NAME} not found"
fi

# Stop and remove local registry
echo -e "\n${YELLOW}Removing local Docker registry...${NC}"
if [ "$(docker ps -aq -f name=${REGISTRY_NAME})" ]; then
    docker stop "${REGISTRY_NAME}"
    docker rm "${REGISTRY_NAME}"
    echo -e "${GREEN}✅ Local registry removed${NC}"
else
    echo "Registry ${REGISTRY_NAME} not found"
fi

# Clean up Docker images (optional)
echo -e "\n${YELLOW}Do you want to remove the built Docker images? (y/n)${NC}"
read -r remove_images

if [[ "$remove_images" =~ ^[Yy]$ ]]; then
    echo "Removing Docker images..."
    docker rmi localhost:5001/todo-frontend:latest 2>/dev/null || true
    docker rmi localhost:5001/todo-service:latest 2>/dev/null || true
    docker rmi localhost:5001/validation-service:latest 2>/dev/null || true
    docker rmi localhost:5001/notification-service:latest 2>/dev/null || true
    echo -e "${GREEN}✅ Docker images removed${NC}"
fi

echo -e "\n${GREEN}✅ Cleanup complete!${NC}"
echo "All demo resources have been removed."