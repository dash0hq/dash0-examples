#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing agentgateway..."

# Create namespace
kubectl create namespace agentgateway-system --dry-run=client -o yaml | kubectl apply -f -

# Install Gateway API CRDs
echo "Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# Install agentgateway CRDs
echo "Installing agentgateway CRDs..."
helm upgrade -i agentgateway-crds oci://ghcr.io/kgateway-dev/charts/agentgateway-crds \
    --namespace agentgateway-system \
    --version v2.2.0-main \
    --set controller.image.pullPolicy=Always \
    --wait \
    --timeout 5m

# Install agentgateway control plane
echo "Installing agentgateway v2.2.0-main control plane..."
helm upgrade -i agentgateway oci://ghcr.io/kgateway-dev/charts/agentgateway \
    --namespace agentgateway-system \
    --version v2.2.0-main \
    --set controller.image.pullPolicy=Always \
    --set controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true \
    --wait \
    --timeout 5m

# Apply Gateway
echo "Applying Gateway..."
kubectl apply -f "$PROJECT_DIR/agentgateway/gateway.yaml"

echo "Waiting for gateway to be ready..."
kubectl wait --for=condition=Programmed gateway/ai-gateway -n agentgateway-system --timeout=300s

echo "agentgateway installed successfully!"
