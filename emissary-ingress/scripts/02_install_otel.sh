#!/bin/bash

# Script to install OpenTelemetry Collector for Emissary-ingress demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📡 Installing OpenTelemetry Stack${NC}"
echo "================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Source .env file from root directory
ENV_FILE="${PROJECT_ROOT}/../.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo -e "${GREEN}✓ Loaded environment from ${ENV_FILE}${NC}"
else
    echo -e "${YELLOW}⚠️  No .env file found at ${ENV_FILE}${NC}"
    echo "Please copy .env.template to .env in the root directory and configure it."
    echo ""
    echo "Required variables:"
    echo "  - DASH0_AUTH_TOKEN"
    echo "  - DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME"
    echo "  - DASH0_ENDPOINT_OTLP_GRPC_PORT"
    echo ""
    read -p "Do you want to enter them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "DASH0_AUTH_TOKEN: " DASH0_AUTH_TOKEN
        read -p "DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME (e.g., ingress.dash0.com): " DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME
        read -p "DASH0_ENDPOINT_OTLP_GRPC_PORT (default: 4317): " DASH0_ENDPOINT_OTLP_GRPC_PORT
        DASH0_ENDPOINT_OTLP_GRPC_PORT=${DASH0_ENDPOINT_OTLP_GRPC_PORT:-4317}
    else
        echo -e "${RED}❌ Environment variables required. Exiting.${NC}"
        exit 1
    fi
fi

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/4: Adding OpenTelemetry Helm repository...${NC}"
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

echo -e "${BLUE}Step 2/4: Creating OpenTelemetry namespace...${NC}"
kubectl create namespace opentelemetry --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 3/4: Creating Dash0 secrets...${NC}"
kubectl create secret generic dash0-secrets \
    --from-literal=dash0-authorization-token="$DASH0_AUTH_TOKEN" \
    --from-literal=dash0-grpc-hostname="$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" \
    --from-literal=dash0-grpc-port="${DASH0_ENDPOINT_OTLP_GRPC_PORT:-4317}" \
    --namespace=opentelemetry \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 4/4: Installing OpenTelemetry Collectors...${NC}"
echo "  - Installing DaemonSet collector..."
helm upgrade --install otel-collector-ds open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-daemonset.yaml" \
    --wait

echo "  - Installing Deployment collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-deployment.yaml" \
    --wait

echo -e "${GREEN}✅ OpenTelemetry stack installed successfully!${NC}"
echo ""
echo "OpenTelemetry components:"
kubectl get pods -n opentelemetry
echo ""
echo "Next step: Run ./scripts/03_install_emissary.sh"