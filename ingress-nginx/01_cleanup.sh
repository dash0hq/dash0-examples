#!/bin/bash

# Cleanup script for ingress-nginx demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up ingress-nginx demo${NC}"
echo "================================="

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${RED}❌ kind is not installed.${NC}"
    exit 1
fi

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "ingress-nginx-demo"; then
    echo -e "${YELLOW}⚠️  Cluster 'ingress-nginx-demo' does not exist.${NC}"
    exit 0
fi

echo -e "${BLUE}Deleting Kind cluster 'ingress-nginx-demo'...${NC}"
kind delete cluster --name ingress-nginx-demo

echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "The following has been removed:"
echo "- Kind cluster 'ingress-nginx-demo'"
echo "- All associated Kubernetes resources"
echo ""
echo "Note: Don't forget to remove the host entry from /etc/hosts if you added it:"
echo "  127.0.0.1 nodejs.localhost"