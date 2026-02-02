#!/bin/bash

# Install Contour with OpenTelemetry support
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Installing Contour with OpenTelemetry${NC}"
echo "========================================"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

# Check if OpenTelemetry namespace exists
if ! kubectl get namespace opentelemetry &>/dev/null; then
    echo -e "${RED}❌ OpenTelemetry namespace not found. Please run 02_install_otel.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/6: Installing Contour Gateway Provisioner (includes Gateway API CRDs)...${NC}"
kubectl apply -f https://projectcontour.io/quickstart/contour-gateway-provisioner.yaml

echo -e "${BLUE}Step 2/6: Waiting for Contour Gateway Provisioner to be ready...${NC}"

kubectl wait --timeout=300s --for=condition=Available deployment/contour-gateway-provisioner -n projectcontour

echo -e "${BLUE}Step 3/6: Ensuring ExtensionService CRD is ready...${NC}"
kubectl wait --timeout=60s --for condition=established crd/extensionservices.projectcontour.io

echo -e "${BLUE}Step 4/6: Creating OpenTelemetry extension service...${NC}"
kubectl apply -f "${PROJECT_ROOT}/contour/extension-service.yaml"

echo -e "${BLUE}Step 5/6: Creating GatewayClass and Gateway...${NC}"
kubectl apply -f "${PROJECT_ROOT}/contour/gateway-resources.yaml"

echo -e "${BLUE}Step 6/6: Waiting for Gateway to be ready...${NC}"
kubectl wait --timeout=300s --for=condition=Programmed gateway/contour -n projectcontour

echo -e "${YELLOW}Waiting for Contour components to recognize new configuration...${NC}"
kubectl rollout restart deployment/contour-contour -n projectcontour
kubectl rollout restart daemonset/envoy-contour -n projectcontour
kubectl rollout status deployment/contour-contour -n projectcontour --timeout=120s
kubectl rollout status daemonset/envoy-contour -n projectcontour --timeout=120s

echo -e "${GREEN}✅ Contour installed successfully!${NC}"
echo ""
echo "Contour components:"
kubectl get pods -n projectcontour
echo ""
echo "Service status:"
kubectl get svc -n projectcontour
echo ""
echo "Gateway:"
kubectl get gateway -n projectcontour
echo ""
echo "Extension services:"
kubectl get extensionservice -n opentelemetry
echo ""
echo "Next step: Run ./scripts/04_deploy_apps.sh"