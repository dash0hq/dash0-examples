#!/bin/bash

# Install OpenTelemetry Collectors (DaemonSet and Deployment)
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
fi

# Check if Dash0 is configured
DASH0_ENABLED=false
if [ -n "${DASH0_AUTH_TOKEN}" ]; then
    DASH0_ENABLED=true
    echo -e "${GREEN}✓ Dash0 export enabled${NC}"
else
    echo -e "${YELLOW}ℹ Dash0 export disabled (DASH0_AUTH_TOKEN not set)${NC}"
    echo -e "${YELLOW}  Telemetry will only be exported to local observability stack${NC}"
fi

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/4: Adding OpenTelemetry Helm repository...${NC}"
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

echo -e "${BLUE}Step 2/5: Creating OpenTelemetry namespace...${NC}"
kubectl create namespace opentelemetry --dry-run=client -o yaml | kubectl apply -f -

# Create Dash0 secrets only if Dash0 is enabled
if [ "$DASH0_ENABLED" = true ]; then
    echo -e "${BLUE}Step 3/5: Creating Dash0 secrets...${NC}"
    kubectl create secret generic dash0-secrets \
        --from-literal=dash0-authorization-token="$DASH0_AUTH_TOKEN" \
        --from-literal=dash0-grpc-hostname="$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" \
        --from-literal=dash0-grpc-port="${DASH0_ENDPOINT_OTLP_GRPC_PORT:-4317}" \
        --namespace=opentelemetry \
        --dry-run=client -o yaml | kubectl apply -f -
else
    echo -e "${BLUE}Step 3/5: Skipping Dash0 secrets (not configured)${NC}"
fi

# Select appropriate collector configurations based on Dash0 enablement
if [ "$DASH0_ENABLED" = true ]; then
    COLLECTOR_DAEMONSET_CONFIG="${PROJECT_ROOT}/collector/otel-collector-daemonset.yaml"
    COLLECTOR_DEPLOYMENT_CONFIG="${PROJECT_ROOT}/collector/otel-collector-deployment.yaml"
else
    COLLECTOR_DAEMONSET_CONFIG="${PROJECT_ROOT}/collector/otel-collector-daemonset-local.yaml"
    COLLECTOR_DEPLOYMENT_CONFIG="${PROJECT_ROOT}/collector/otel-collector-deployment-local.yaml"
fi

echo -e "${BLUE}Step 4/5: Installing OpenTelemetry Collectors...${NC}"
echo "  - Installing DaemonSet collector..."
helm upgrade --install otel-collector-ds open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "$COLLECTOR_DAEMONSET_CONFIG" \
    --wait

echo "  - Installing Deployment collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "$COLLECTOR_DEPLOYMENT_CONFIG" \
    --wait

echo -e "${GREEN}✅ OpenTelemetry stack installed successfully!${NC}"
echo ""
echo "OpenTelemetry components:"
kubectl get pods -n opentelemetry
echo ""
