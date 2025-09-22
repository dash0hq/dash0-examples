#!/bin/bash

# Cleanup script for Contour demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up Contour demo${NC}"
echo "============================"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${RED}❌ kind is not installed.${NC}"
    exit 1
fi

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "contour-demo"; then
    echo -e "${YELLOW}⚠️  Cluster 'contour-demo' does not exist.${NC}"
    exit 0
fi

echo -e "${BLUE}Deleting Kind cluster 'contour-demo'...${NC}"
kind delete cluster --name contour-demo

echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "The following has been removed:"
echo "- Kind cluster 'contour-demo'"
echo "- All associated Kubernetes resources"
echo ""
echo "Note: If you have any port-forward processes running, you may want to kill them:"
echo "  pkill -f 'kubectl port-forward'"