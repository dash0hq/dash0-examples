#!/bin/bash

# Deploy test applications and configure ingress
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying Test Applications${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

# Check if ingress-nginx is running
if ! kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx 2>/dev/null | grep -q Running; then
    echo -e "${RED}❌ ingress-nginx is not running. Please run 03_install_nginx.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/3: Building Node.js application...${NC}"
"${SCRIPT_DIR}/05_build_nodejs_app.sh"

echo -e "${BLUE}Step 2/3: Deploying Node.js application...${NC}"
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "${PROJECT_ROOT}/services/nodejs-app/manifests/"

echo -e "${BLUE}Step 3/3: Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=nodejs-app -n demo --timeout=120s

echo -e "${GREEN}✅ Applications deployed successfully!${NC}"
echo ""
echo "Deployed applications:"
kubectl get pods -n demo
echo ""
echo "Services:"
kubectl get svc -n demo
echo ""
echo "Ingress:"
kubectl get ingress -n demo
echo ""
echo -e "${YELLOW}📝 To access the application:${NC}"
echo "1. Add to /etc/hosts:"
echo "   127.0.0.1 nodejs.localhost"
echo ""
echo "2. Access services:"
echo "   - Node.js App: http://nodejs.localhost"
echo ""
echo "Next step: Run ./scripts/load-test.sh to generate traffic"