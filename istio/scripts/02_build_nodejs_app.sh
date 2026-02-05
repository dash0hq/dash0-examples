#!/bin/bash

# Build and load services to Kind cluster
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 Building services${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if Docker is running
if ! docker info &>/dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Build service-a
echo -e "${BLUE}Building service-a...${NC}"
docker build -t service-a:latest "${PROJECT_ROOT}/services/service-a"
kind load docker-image service-a:latest --name istio-demo

# Build service-b
echo -e "${BLUE}Building service-b...${NC}"
docker build -t service-b:latest "${PROJECT_ROOT}/services/service-b"
kind load docker-image service-b:latest --name istio-demo

echo -e "${GREEN}✅ Services built and loaded successfully!${NC}"
echo ""
echo "Images:"
echo "  - service-a:latest"
echo "  - service-b:latest"
echo ""
