#!/bin/bash

# Build and push Docker images for all services
# This script builds all service images and pushes them to the local registry

set -e

REGISTRY_PORT="${REGISTRY_PORT:-5001}"
SKIP_TESTS="${SKIP_TESTS:-true}"
TAG="${TAG:-v1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🏗️  Building Service Docker Images${NC}"
echo "====================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if registry is running
if ! docker ps | grep -q kind-registry; then
    echo -e "${RED}❌ Local registry is not running. Please run 01_setup_kind.sh first.${NC}"
    exit 1
fi

# Function to build and push image
build_and_push() {
    local service_name=$1
    local service_path=$2
    local build_type=$3
    
    echo -e "\n${BLUE}Building ${service_name}...${NC}"
    
    cd "${PROJECT_ROOT}/${service_path}"
    
    if [ "$build_type" = "java" ]; then
        # Build Java service
        if [ -f "mvnw" ]; then
            echo "Running Maven build..."
            if [ "$SKIP_TESTS" = "true" ]; then
                ./mvnw clean package -DskipTests
            else
                ./mvnw clean package
            fi
        else
            echo -e "${RED}❌ Maven wrapper not found in ${service_path}${NC}"
            return 1
        fi
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -t "localhost:${REGISTRY_PORT}/${service_name}:${TAG}" .
    
    # Push to registry
    echo "Pushing to registry..."
    docker push "localhost:${REGISTRY_PORT}/${service_name}:${TAG}"
    
    echo -e "${GREEN}✅ ${service_name} built and pushed successfully${NC}"
}

# Build all services
echo -e "${YELLOW}Building all services...${NC}"

# Build frontend
build_and_push "frontend" "services/frontend" "node"

# Build Java services
build_and_push "todo-service" "services/todo-service" "java"
build_and_push "validation-service" "services/validation-service" "java"
build_and_push "notification-service" "services/notification-service" "java"

cd "${PROJECT_ROOT}"

echo -e "\n${GREEN}✅ All images built and pushed successfully!${NC}"
echo ""
echo "Images built with tag: ${TAG}"
echo "Images available in registry:"
docker images | grep "localhost:${REGISTRY_PORT}" | grep "${TAG}" | awk '{print "  - " $1 ":" $2}'
echo ""
echo "Next step: Run ./scripts/04_deploy_databases.sh"