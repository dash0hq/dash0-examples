#!/bin/bash

# Cleanup script for Hostmetrics Demo
# This script removes the Kind cluster and all associated resources

set -e

CLUSTER_NAME="${CLUSTER_NAME:-hostmetrics-demo}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Hostmetrics Demo - Cleanup${NC}"
echo "=============================="
echo ""
echo "This will remove:"
echo "  - Kind cluster: ${CLUSTER_NAME}"
echo "  - All deployed resources"
echo ""
echo -e "${RED}⚠️  This action cannot be undone!${NC}"
echo -n "Are you sure you want to continue? (y/n): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Check if Kind is installed
if ! command -v kind >/dev/null 2>&1; then
    echo -e "${RED}❌ Kind is not installed. Nothing to clean up.${NC}"
    exit 1
fi

# Check if cluster exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}ℹ️  Cluster ${CLUSTER_NAME} does not exist. Nothing to clean up.${NC}"
    exit 0
fi

echo -e "${BLUE}Deleting Kind cluster...${NC}"
kind delete cluster --name="${CLUSTER_NAME}"

echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "The Kind cluster and all resources have been removed."
echo "To redeploy, run: ./00_run.sh"