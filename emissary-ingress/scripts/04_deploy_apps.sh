#!/bin/bash

# Script to deploy demo applications for Emissary-ingress demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying demo applications${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Build and deploy Node.js application with OpenTelemetry auto-instrumentation
echo -e "${BLUE}🏗️  Building Node.js application image${NC}"
cd "${PROJECT_DIR}/services/nodejs-app"
docker build -t nodejs-app:v1 . || { echo -e "${RED}❌ Failed to build image${NC}"; exit 1; }

echo -e "${BLUE}📥 Loading image into Kind cluster${NC}"
kind load docker-image nodejs-app:v1 --name emissary-demo || { echo -e "${RED}❌ Failed to load image into cluster${NC}"; exit 1; }

echo -e "${BLUE}📦 Creating demo namespace${NC}"
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}📦 Deploying Node.js application${NC}"
kubectl apply -f "${PROJECT_DIR}/services/nodejs-app/manifests/"

# Wait for deployment to be ready
echo -e "${BLUE}⏳ Waiting for Node.js app to be ready...${NC}"
kubectl rollout status deployment/nodejs-app -n demo --timeout=300s

echo ""
echo -e "${GREEN}✅ Applications deployed successfully!${NC}"
echo ""
kubectl get pods
echo ""
kubectl get svc

echo ""
echo -e "${YELLOW}🌐 Service Access:${NC}"
echo "  Main Ingress: kubectl port-forward svc/emissary-ingress -n emissary 8080:80"
echo "  Admin Interface: kubectl port-forward svc/emissary-ingress-admin -n emissary 8877:8877"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Port-forward the ingress: kubectl port-forward svc/emissary-ingress -n emissary 8080:80"
echo "  2. Test the application: curl -H 'Host: node.dash0-examples.com' http://localhost:8080/"
echo "  3. Run load test: ./scripts/load-test.sh"