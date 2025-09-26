#!/bin/bash

# Script to install Emissary-ingress with OpenTelemetry support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Installing Emissary-ingress${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Add Emissary Helm repository
echo -e "${BLUE}📦 Adding Emissary Helm repository${NC}"
helm repo add datawire https://app.getambassador.io
helm repo update

# Clean up any existing installations
echo -e "${BLUE}🧹 Cleaning up existing installations...${NC}"
kubectl delete namespace emissary-system --ignore-not-found=true
kubectl delete namespace emissary --ignore-not-found=true

# Create emissary namespace (standard approach)
echo -e "${BLUE}🔧 Creating emissary namespace${NC}"
kubectl create namespace emissary --dry-run=client -o yaml | kubectl apply -f -

# Install CRDs
echo -e "${BLUE}📋 Installing Emissary CRDs${NC}"
kubectl apply -f https://app.getambassador.io/yaml/emissary/latest/emissary-crds.yaml

# Wait for CRD controller to be ready
echo -e "${BLUE}⏳ Waiting for CRD controller to be ready...${NC}"
kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system

# Install Emissary using Helm
echo -e "${BLUE}🎯 Installing Emissary-ingress with Helm${NC}"
helm install emissary-ingress --namespace emissary datawire/emissary-ingress \
    --values "${PROJECT_DIR}/emissary-ingress/values.yaml"

# Wait for deployment to be ready
echo -e "${BLUE}⏳ Waiting for Emissary-ingress to be ready...${NC}"
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress

# Apply Listener configuration (required for Emissary v3)
echo -e "${BLUE}🎯 Creating Listener for HTTP traffic...${NC}"
kubectl apply -f "${PROJECT_DIR}/emissary-ingress/listener.yaml"

# Apply OpenTelemetry tracing configuration
echo -e "${BLUE}🔭 Configuring OpenTelemetry tracing...${NC}"
kubectl apply -f "${PROJECT_DIR}/emissary-ingress/tracing-service.yaml"

# Apply Ambassador module configuration for observability
echo -e "${BLUE}🔧 Applying Ambassador module configuration...${NC}"
kubectl apply -f "${PROJECT_DIR}/emissary-ingress/ambassador-module.yaml"

echo -e "${BLUE}🗺️  Applying ingress mappings...${NC}"
kubectl apply -f "${PROJECT_DIR}/emissary-ingress/mappings.yaml"

# Restart Emissary to ensure tracing configuration is picked up
echo -e "${BLUE}🔄 Restarting Emissary to apply tracing configuration...${NC}"
kubectl rollout restart deployment emissary-ingress -n emissary
kubectl rollout status deployment emissary-ingress -n emissary

echo ""
echo -e "${GREEN}✅ Emissary-ingress installed successfully!${NC}"
echo ""
kubectl get pods -n emissary
echo ""
kubectl get svc -n emissary

echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  Run: ./scripts/04_deploy_apps.sh"