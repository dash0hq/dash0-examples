#!/bin/bash

# Cleanup script for Linkerd demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Cleaning up Linkerd Demo${NC}"
echo "========================="

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "linkerd-demo"; then
    echo -e "${YELLOW}Cluster 'linkerd-demo' does not exist. Nothing to clean up.${NC}"
    exit 0
fi

echo -e "${BLUE}Deleting Kind cluster 'linkerd-demo'...${NC}"
kind delete cluster --name linkerd-demo

echo -e "${GREEN}Cleanup complete!${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} If you have port-forward processes running, kill them with:"
echo "  pkill -f 'kubectl port-forward'"
echo ""
