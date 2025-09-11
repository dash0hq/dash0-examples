#!/bin/bash

# Install OpenTelemetry Collector using Helm
# This script installs the OpenTelemetry collector to receive and forward metrics to Dash0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📡 Installing OpenTelemetry Collector${NC}"
echo "====================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Source .env file
if [ -f "${PROJECT_ROOT}/../.env" ]; then
    source "${PROJECT_ROOT}/../.env"
else
    echo -e "${RED}Error: .env file not found. Please copy .env.template to .env and configure your settings.${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_kind.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/4: Adding OpenTelemetry Helm repository...${NC}"
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

echo -e "${BLUE}Step 2/4: Creating OpenTelemetry namespace...${NC}"
kubectl create namespace opentelemetry --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 3/4: Creating Dash0 secrets for OpenTelemetry collector...${NC}"
kubectl create secret generic dash0-secrets \
    --from-literal=dash0-authorization-token="$DASH0_AUTH_TOKEN" \
    --from-literal=dash0-dataset="$DASH0_DATASET" \
    --from-literal=dash0-grpc-hostname="$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" \
    --from-literal=dash0-grpc-port="$DASH0_ENDPOINT_OTLP_GRPC_PORT" \
    --namespace=opentelemetry \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 4/5: Installing OpenTelemetry Collector (Deployment)...${NC}"
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-deployment.yaml" \
    --wait

echo -e "${BLUE}Step 5/5: Installing OpenTelemetry Collector (DaemonSet)...${NC}"
helm upgrade --install otel-daemonset open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-daemonset.yaml" \
    --wait

echo -e "${GREEN}✅ OpenTelemetry Collector installed successfully!${NC}"
echo ""
echo "OpenTelemetry collector pods:"
kubectl get pods -n opentelemetry
echo ""
echo "Collector services:"
kubectl get svc -n opentelemetry