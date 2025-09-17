#!/bin/bash

# Build Node.js app and load into Kind cluster
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 Building Node.js Demo App${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Set variables
IMAGE_NAME="nodejs-app"
TAG="${TAG:-v1}"
CLUSTER_NAME="ingress-nginx-demo"

echo -e "${BLUE}Building Docker image...${NC}"
cd "${PROJECT_ROOT}/services/nodejs-app"

# Create package-lock.json if it doesn't exist
if [ ! -f package-lock.json ]; then
    npm install --package-lock-only
fi

# Build image
docker build -t ${IMAGE_NAME}:${TAG} .

echo -e "${BLUE}Loading image into Kind cluster...${NC}"
kind load docker-image ${IMAGE_NAME}:${TAG} --name ${CLUSTER_NAME}

echo -e "${GREEN}✅ Node.js app built and loaded into Kind successfully!${NC}"
echo ""
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""
echo "Next step: Deploy the app with kubectl apply -f services/nodejs-app/manifests/"