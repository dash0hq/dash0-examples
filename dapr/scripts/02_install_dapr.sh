#!/bin/bash

# Install Dapr on Kubernetes cluster
# This script installs Dapr using Helm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎯 Installing Dapr on Kubernetes${NC}"
echo "===================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

if ! command_exists helm; then
    echo -e "${RED}❌ Helm is not installed. Please install Helm first.${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_kind.sh first.${NC}"
    exit 1
fi

# Add Dapr Helm repo
echo "Adding Dapr Helm repository..."
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

# Check if Dapr is already installed
if helm list -n dapr-system 2>/dev/null | grep -q dapr; then
    echo -e "${YELLOW}ℹ️  Dapr is already installed${NC}"
    echo -n "Do you want to upgrade it? (y/n): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Upgrading Dapr..."
        helm upgrade dapr dapr/dapr \
            --namespace dapr-system \
            --set global.ha.enabled=false \
            --set global.mtls.enabled=false \
            --wait
        echo -e "${GREEN}✅ Dapr upgraded successfully${NC}"
    else
        echo "Keeping existing Dapr installation..."
    fi
else
    echo "Installing Dapr..."
    helm install dapr dapr/dapr \
        --namespace dapr-system \
        --create-namespace \
        --set global.ha.enabled=false \
        --set global.mtls.enabled=false \
        --wait
    echo -e "${GREEN}✅ Dapr installed successfully${NC}"
fi

# Verify installation
echo ""
echo "Dapr components:"
kubectl get pods -n dapr-system

echo ""
echo -e "${GREEN}✅ Dapr installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  - Run ./scripts/03_build_images.sh to build service images"
echo "  - Run ./scripts/04_deploy_databases.sh to deploy databases"
echo ""
echo "To access Dapr dashboard:"
echo "  kubectl port-forward svc/dapr-dashboard 8080:8080 -n dapr-system"