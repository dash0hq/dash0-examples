#!/bin/bash

# Deploy demo applications
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📦 Deploying demo applications${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/2: Deploying Node.js application...${NC}"
kubectl apply -f "${PROJECT_ROOT}/services/nodejs-app/manifests/deployment.yaml"

echo -e "${BLUE}Step 2/2: Creating HTTPRoute for routing...${NC}"
kubectl apply -f "${PROJECT_ROOT}/kgateway/httproute.yaml"

echo -e "${BLUE}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/nodejs-app -n demo || true

echo -e "${GREEN}✅ Applications deployed successfully!${NC}"
echo ""
echo "Application pods:"
kubectl get pods -n demo
echo ""
echo "HTTPRoutes:"
kubectl get httproute -n demo
echo ""
echo -e "${GREEN}🎉 Demo is ready!${NC}"
echo ""
echo "Access the gateway:"
echo "  kubectl port-forward -n kgateway-system svc/http 8080:80"
echo ""
echo "Test the application:"
echo "  curl -H 'Host: node.dash0-examples.com' http://localhost:8080/"
echo ""
