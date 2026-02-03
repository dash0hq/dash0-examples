#!/bin/bash

# Script to install Emissary-ingress v4.0.0-rc.1 with OpenTelemetry support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Installing Emissary-ingress v4.0.0-rc.1${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Clean up any existing installations
echo -e "${BLUE}🧹 Cleaning up existing installations...${NC}"
kubectl delete namespace emissary --ignore-not-found=true

# Delete existing CRDs if present
echo -e "${BLUE}🧹 Cleaning up existing CRDs...${NC}"
kubectl get crds | grep getambassador.io | awk '{print $1}' | xargs kubectl delete crd --ignore-not-found=true 2>/dev/null || true

# Create emissary namespace
echo -e "${BLUE}🔧 Creating emissary namespace${NC}"
kubectl create namespace emissary --dry-run=client -o yaml | kubectl apply -f -

# Install CRDs using Helm
echo -e "${BLUE}📋 Installing Emissary v4.0.0-rc.1 CRDs${NC}"
helm install emissary-crds oci://ghcr.io/emissary-ingress/emissary-crds-chart \
    --version=4.0.0-rc.1 \
    --wait

# Install Emissary using Helm (OCI registry)
echo -e "${BLUE}🎯 Installing Emissary-ingress v4.0.0-rc.1 with Helm${NC}"
helm install emissary \
    --namespace emissary \
    oci://ghcr.io/emissary-ingress/emissary-ingress \
    --version=4.0.0-rc.1 \
    -f "${PROJECT_DIR}/emissary-ingress/values.yaml" \
    --wait

# Wait for deployment to be ready
echo -e "${BLUE}⏳ Waiting for Emissary-ingress to be ready...${NC}"
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary

# Apply Listener configuration
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
kubectl rollout restart deployment emissary -n emissary
kubectl rollout status deployment emissary -n emissary

echo ""
echo -e "${GREEN}✅ Emissary-ingress v4.0.0-rc.1 installed successfully!${NC}"
echo ""
kubectl get pods -n emissary
echo ""
kubectl get svc -n emissary

echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  Run: ./scripts/04_deploy_apps.sh"
