#!/bin/bash

# Deploy application services
# This script deploys all microservices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying Application Services${NC}"
echo "===================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_kind.sh first.${NC}"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace dapr-demo &>/dev/null; then
    echo -e "${RED}❌ Namespace 'dapr-demo' does not exist. Please run 04_deploy_databases.sh first.${NC}"
    exit 1
fi

# Check if images exist in registry
REGISTRY_PORT="${REGISTRY_PORT:-5001}"
echo -e "${YELLOW}Checking for required images...${NC}"
required_images=("todo-service" "validation-service" "notification-service" "frontend")
missing_images=()

for image in "${required_images[@]}"; do
    if ! docker images | grep -q "localhost:${REGISTRY_PORT}/${image}"; then
        missing_images+=("$image")
    fi
done

if [ ${#missing_images[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing images: ${missing_images[*]}${NC}"
    echo "Please run ./scripts/03_build_images.sh first."
    exit 1
fi

echo -e "${BLUE}Deploying services...${NC}"

# Deploy backend services first
echo "  - Todo Service"
kubectl apply -f "${PROJECT_ROOT}/services/todo-service/manifests/"

echo "  - Validation Service"
kubectl apply -f "${PROJECT_ROOT}/services/validation-service/manifests/"

echo "  - Notification Service"
kubectl apply -f "${PROJECT_ROOT}/services/notification-service/manifests/"

# Deploy frontend last
echo "  - Frontend"
kubectl apply -f "${PROJECT_ROOT}/services/frontend/manifests/"

# Wait for services to be ready
echo -e "\n${YELLOW}Waiting for services to be ready...${NC}"

services=("todo-service" "validation-service" "notification-service" "frontend")
for service in "${services[@]}"; do
    echo -n "Waiting for ${service}..."
    kubectl wait --for=condition=ready pod -l app=${service} -n dapr-demo --timeout=120s 2>/dev/null || {
        echo -e "\n${YELLOW}⚠️  ${service} is taking longer than expected to start${NC}"
        echo "Check logs with: kubectl logs -l app=${service} -n dapr-demo"
    }
    echo -e " ${GREEN}✓${NC}"
done

echo -e "\n${GREEN}✅ All services deployed!${NC}"
echo ""
echo "Service status:"
kubectl get pods -n dapr-demo -l 'app in (todo-service, validation-service, notification-service, frontend)'
echo ""
echo "Services available:"
echo "  - Frontend: http://localhost:31000"
echo "  - Todo Service: Internal (port 8080)"
echo "  - Validation Service: Internal (port 8081)"
echo "  - Notification Service: Internal (port 8082)"
echo ""
echo "View logs:"
echo "  kubectl logs -f <pod-name> -n dapr-demo              # App logs"
echo "  kubectl logs -f <pod-name> -c daprd -n dapr-demo     # Dapr sidecar logs"
echo ""
echo "🎉 Deployment complete! Access the application at http://localhost:31000"