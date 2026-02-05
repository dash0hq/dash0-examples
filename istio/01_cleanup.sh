#!/bin/bash

# Cleanup script for Istio demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up Istio demo environment${NC}"
echo "===================================="

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "istio-demo"; then
    echo -e "${YELLOW}Cluster 'istio-demo' does not exist. Nothing to clean up.${NC}"
    exit 0
fi

echo -e "${BLUE}Deleting Kind cluster 'istio-demo'...${NC}"
kind delete cluster --name istio-demo

echo -e "${GREEN}✅ Cleanup complete!${NC}"
