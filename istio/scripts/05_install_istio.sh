#!/bin/bash

# Install Istio with OpenTelemetry configuration using Helm
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Installing Istio with OpenTelemetry (Helm)${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

# Istio version
ISTIO_VERSION="1.28.3"

echo -e "${BLUE}Step 1/5: Adding Istio Helm repository...${NC}"
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio

echo -e "${BLUE}Step 2/5: Creating istio-system namespace...${NC}"
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 3/5: Installing Istio base chart...${NC}"
helm upgrade --install istio-base istio/base \
  --namespace istio-system \
  --version ${ISTIO_VERSION} \
  --wait

echo -e "${BLUE}Step 4/5: Installing Istiod (control plane)...${NC}"
helm upgrade --install istiod istio/istiod \
  --namespace istio-system \
  --version ${ISTIO_VERSION} \
  --values "${PROJECT_ROOT}/istio/values.yaml" \
  --wait

echo -e "${BLUE}Step 5/5: Installing Istio ingress gateway...${NC}"
helm upgrade --install istio-ingressgateway istio/gateway \
  --namespace istio-system \
  --version ${ISTIO_VERSION} \
  --values "${PROJECT_ROOT}/istio/gateway-values.yaml" \
  --wait

echo -e "${GREEN}✅ Istio installed successfully!${NC}"
echo ""
echo "Istio components:"
kubectl get pods -n istio-system
echo ""
echo "Istio version:"
kubectl get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].spec.containers[0].image}'
echo ""
