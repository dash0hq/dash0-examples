#!/bin/bash

# Install ingress-nginx with OpenTelemetry support
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Installing ingress-nginx with OpenTelemetry${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/3: Adding ingress-nginx Helm repository...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo -e "${BLUE}Step 2/3: Creating ingress-nginx namespace...${NC}"
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 3/3: Installing ingress-nginx...${NC}"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    -f "${PROJECT_ROOT}/ingress-nginx/values.yaml" \
    --wait

echo -e "${GREEN}✅ ingress-nginx installed successfully!${NC}"
echo ""
echo "ingress-nginx components:"
kubectl get pods -n ingress-nginx
echo ""
echo "Service status:"
kubectl get svc -n ingress-nginx
echo ""
echo "Next step: Run ./scripts/04_deploy_apps.sh"