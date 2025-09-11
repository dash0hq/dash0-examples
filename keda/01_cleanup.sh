#!/bin/bash

# KEDA Demo Cleanup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 KEDA Demo Cleanup${NC}"
echo "====================="
echo ""
echo "This will remove:"
echo "  - Kind cluster (keda-demo)"
echo "  - All associated resources"
echo ""
echo -n "Continue with cleanup? (y/n): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete Kind cluster
echo -e "\n${BLUE}Deleting Kind cluster...${NC}"
if kind get clusters | grep -q "keda-demo"; then
    kind delete cluster --name keda-demo
    echo -e "${GREEN}✅ Kind cluster deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Cluster 'keda-demo' not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Cleanup complete!${NC}"