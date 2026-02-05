#!/bin/bash

# Deploy demo applications
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying Demo Applications${NC}"
echo "=============================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/5: Deploying service-a (frontend)...${NC}"
kubectl apply -f "${PROJECT_ROOT}/services/service-a/manifests/deployment.yaml"

echo -e "${BLUE}Step 2/5: Deploying service-b (backend)...${NC}"
kubectl apply -f "${PROJECT_ROOT}/services/service-b/manifests/deployment.yaml"

echo -e "${BLUE}Step 3/6: Deploying Istio Gateway and VirtualService...${NC}"
kubectl apply -f "${PROJECT_ROOT}/istio/gateway.yaml"

echo -e "${BLUE}Step 4/6: Applying Istio Telemetry configuration...${NC}"
kubectl apply -f "${PROJECT_ROOT}/istio/telemetry.yaml"

echo -e "${BLUE}Step 5/6: Applying Gateway-specific Telemetry configuration...${NC}"
kubectl apply -f "${PROJECT_ROOT}/istio/telemetry-gateway.yaml"

echo -e "${BLUE}Step 6/6: Waiting for applications to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=service-a -n demo --timeout=180s
kubectl wait --for=condition=ready pod -l app=service-b -n demo --timeout=180s

echo -e "${GREEN}✅ Applications deployed successfully!${NC}"
echo ""
echo "Deployed applications:"
kubectl get pods -n demo
echo ""
echo "Services:"
kubectl get svc -n demo
echo ""
echo "Gateway configuration:"
kubectl get gateway,virtualservice -n demo
echo ""
echo "To test the application:"
echo "  kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80 &"
echo ""
echo "Test service-a:"
echo "  curl -H 'Host: service-a.dash0-examples.com' http://localhost:8080/"
echo ""
echo "Test service mesh communication (service-a → service-b):"
echo "  curl -H 'Host: service-a.dash0-examples.com' http://localhost:8080/api/backend"
echo ""
