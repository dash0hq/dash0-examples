#!/bin/bash

# Cleanup script for kgateway demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up kgateway demo${NC}"
echo "================================="

echo -e "${BLUE}Deleting Kind cluster...${NC}"
kind delete cluster --name kgateway-demo

echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
