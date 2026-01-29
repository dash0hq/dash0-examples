#!/bin/bash

# Install kgateway
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Installing kgateway${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/6: Installing Gateway API CRDs...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

echo -e "${BLUE}Step 2/6: Creating kgateway-system namespace...${NC}"
kubectl create namespace kgateway-system --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 3/7: Installing kgateway CRDs...${NC}"
helm upgrade -i \
    --namespace kgateway-system \
    --version v2.2.0-rc.2 kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds

echo -e "${BLUE}Step 4/7: Installing kgateway control plane...${NC}"
helm upgrade -i -n kgateway-system kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
    --version v2.2.0-rc.2 \
    --wait \
    --timeout 5m

echo -e "${BLUE}Step 5/7: Applying GatewayParameters...${NC}"
kubectl apply -f "${PROJECT_ROOT}/kgateway/gateway-parameters.yaml"

echo -e "${BLUE}Step 6/7: Applying Gateway API resources...${NC}"
kubectl apply -f "${PROJECT_ROOT}/kgateway/gateway.yaml"

echo -e "${BLUE}Step 7/7: Configuring telemetry (tracing and access logs)...${NC}"
kubectl apply -f "${PROJECT_ROOT}/kgateway/referencegrant.yaml"
kubectl apply -f "${PROJECT_ROOT}/kgateway/httplistenerpolicy.yaml"

echo -e "${BLUE}Waiting for gateway to be ready...${NC}"
kubectl wait --for=condition=Programmed gateway/http -n kgateway-system --timeout=120s || true

echo -e "${GREEN}✅ kgateway installed successfully!${NC}"
echo ""
echo "kgateway components:"
kubectl get pods -n kgateway-system
echo ""
echo "Gateway status:"
kubectl get gateway -n kgateway-system
echo ""
