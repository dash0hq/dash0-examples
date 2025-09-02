#!/bin/bash

# Install OpenTelemetry Collector with hostmetrics receiver
# This script installs the OpenTelemetry Collector as a DaemonSet to collect host metrics

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📡 Installing OpenTelemetry Collector${NC}"
echo "===================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Source .env file from parent directory
if [ -f "${PROJECT_ROOT}/../.env" ]; then
    source "${PROJECT_ROOT}/../.env"
else
    echo -e "${RED}Error: .env file not found. Please copy .env.template to .env and configure your Dash0 settings.${NC}"
    echo "Expected location: ${PROJECT_ROOT}/../.env"
    exit 1
fi

# Validate required environment variables
if [ -z "$DASH0_AUTH_TOKEN" ] || [ -z "$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" ] || [ -z "$DASH0_ENDPOINT_OTLP_GRPC_PORT" ]; then
    echo -e "${RED}Error: Missing required Dash0 configuration in .env file${NC}"
    echo "Please ensure the following variables are set:"
    echo "  - DASH0_AUTH_TOKEN"
    echo "  - DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME"
    echo "  - DASH0_ENDPOINT_OTLP_GRPC_PORT"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run ./scripts/01_setup_kind.sh first.${NC}"
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
    --from-literal=dash0-grpc-port="$DASH0_ENDPOINT_OTLP_GRPC_PORT" \
    --namespace=opentelemetry \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 4/4: Installing OpenTelemetry Collector DaemonSet...${NC}"
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-values.yaml"

echo -e "${BLUE}Waiting for DaemonSet to be created...${NC}"
sleep 5  # Give Helm time to create resources

echo -e "${BLUE}Waiting for collector pods to be scheduled...${NC}"
kubectl wait --for=jsonpath='{.status.numberReady}'=2 daemonset/otel-collector-opentelemetry-collector-agent -n opentelemetry --timeout=120s

echo -e "${BLUE}Waiting for collector pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-collector -n opentelemetry --timeout=120s

echo -e "${GREEN}✅ OpenTelemetry Collector installed successfully!${NC}"
echo ""
echo "Collector pods status:"
kubectl get pods -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector
echo ""
echo "To view collector logs:"
echo "  kubectl logs -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector --tail=50 -f"
echo ""
echo "Metrics being collected:"
echo "  - CPU utilization and time"
echo "  - Memory utilization and usage"  
echo "  - System load"
echo "  - Disk I/O"
echo "  - Filesystem utilization"
echo "  - Network statistics"
echo "  - Paging statistics"
echo "  - Process information"
echo ""
echo "All metrics are being exported to Dash0"