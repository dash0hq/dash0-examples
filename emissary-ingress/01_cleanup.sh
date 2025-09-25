#!/bin/bash

# Cleanup script for Emissary-ingress demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="emissary-demo"

echo -e "${BLUE}🧹 Cleaning up Emissary-ingress demo${NC}"
echo "=========================================="

# Check if cluster exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}⚠️  Cluster ${CLUSTER_NAME} does not exist${NC}"
    exit 0
fi

echo -e "${YELLOW}This will delete:${NC}"
echo "  - Kind cluster: ${CLUSTER_NAME}"
echo "  - All deployed applications"
echo "  - All OpenTelemetry collectors"
echo "  - Emissary-ingress installation"
echo ""
echo -n "Are you sure you want to continue? (y/n): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}🗑️  Deleting Kind cluster: ${CLUSTER_NAME}${NC}"
kind delete cluster --name="${CLUSTER_NAME}"

echo ""
echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"