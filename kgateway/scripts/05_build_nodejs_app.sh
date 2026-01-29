#!/bin/bash

# Build and push Node.js application to local registry
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 Building Node.js application${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"
APP_DIR="${PROJECT_ROOT}/services/nodejs-app"

# Check if Docker is running
if ! docker info &>/dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${BLUE}Building Docker image...${NC}"
docker build -t nodejs-app:latest "${APP_DIR}"

echo -e "${BLUE}Loading image into Kind cluster...${NC}"
kind load docker-image nodejs-app:latest --name kgateway-demo

echo -e "${GREEN}✅ Node.js application built and loaded successfully!${NC}"
echo ""
echo "Image: nodejs-app:latest"
echo ""
