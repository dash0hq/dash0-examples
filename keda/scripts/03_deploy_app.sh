#!/bin/bash

# Deploy sample application for KEDA scaling

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="${SCRIPT_DIR}/../app"

echo -e "${GREEN}Deploying sample application...${NC}"

# Install OpenTelemetry Collector first
echo -e "${BLUE}Installing OpenTelemetry Collector...${NC}"
${SCRIPT_DIR}/03_install_otel.sh

# Build the application image
echo -e "${BLUE}Building application image...${NC}"
docker build -t keda-demo-app:v1 "${APP_DIR}"

# Load image into Kind cluster
echo -e "${BLUE}Loading image into Kind cluster...${NC}"
kind load docker-image keda-demo-app:v1 --name keda-demo

# Create namespace
kubectl create namespace keda-demo --dry-run=client -o yaml | kubectl apply -f -

# Deploy the application
kubectl apply -f "${SCRIPT_DIR}/../manifests/deployment.yaml"

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/keda-demo-app -n keda-demo --timeout=120s

echo -e "${GREEN}✅ Sample application deployed successfully${NC}"

# Show pods
echo ""
echo "Application pods:"
kubectl get pods -n keda-demo