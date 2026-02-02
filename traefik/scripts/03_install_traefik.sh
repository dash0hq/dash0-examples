#!/bin/bash

# Install Traefik with observability enabled
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔀 Installing Traefik Ingress Controller${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

# Check if OpenTelemetry collector is running
if ! kubectl get pods -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector 2>/dev/null | grep -q Running; then
    echo -e "${YELLOW}⚠️  OpenTelemetry collector not found or not running.${NC}"
    echo "Please run 02_install_otel.sh first."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}Step 1/3: Adding Traefik Helm repository...${NC}"
helm repo add traefik https://traefik.github.io/charts
helm repo update

echo -e "${BLUE}Step 2/3: Creating Traefik namespace...${NC}"
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 3/3: Installing Traefik with Helm...${NC}"
helm upgrade --install traefik traefik/traefik \
    --namespace traefik \
    --version 39.0.0 \
    --create-namespace \
    -f "${PROJECT_ROOT}/traefik/values.yaml"

echo -e "${BLUE}Waiting for Traefik to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/traefik -n traefik || true

echo -e "${GREEN}✅ Traefik installed successfully!${NC}"
echo ""
echo "Traefik pods:"
kubectl get pods -n traefik
echo ""
echo "Traefik services:"
kubectl get svc -n traefik
echo ""
echo "Dashboard available at: http://localhost:8080/dashboard/"
echo "(After running: kubectl port-forward -n traefik svc/traefik 8080:8080)"
echo ""
echo "Next step: Run ./scripts/04_deploy_apps.sh"