#!/bin/bash

# Install OpenTelemetry Operator and Collector
# This script installs cert-manager, OpenTelemetry operator, collector, and instrumentation

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

# Source .env file
if [ -f "${PROJECT_ROOT}/../.env" ]; then
    source "${PROJECT_ROOT}/../.env"
else
    echo -e "${RED}Error: .env file not found. Please copy .env.template to .env and configure your settings.${NC}"
    exit 1
fi

# Set defaults
VERSION=${VERSION:-v0.0}
CLUSTER_NAME=${CLUSTER_NAME:-dapr-demo}

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_kind.sh first.${NC}"
    exit 1
fi

# Check if Dapr is installed
if ! kubectl get namespace dapr-system &>/dev/null; then
    echo -e "${RED}❌ Dapr is not installed. Please run 02_install_dapr.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/7: Adding required Helm repositories...${NC}"
helm repo add jetstack https://charts.jetstack.io
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

echo -e "${BLUE}Step 2/7: Installing cert-manager (prerequisite for OpenTelemetry operator)...${NC}"
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set crds.enabled=true

echo -e "${BLUE}Waiting for cert-manager to be ready...${NC}"
kubectl wait --for=condition=available deployment/cert-manager -n cert-manager --timeout=120s
kubectl wait --for=condition=available deployment/cert-manager-cainjector -n cert-manager --timeout=120s
kubectl wait --for=condition=available deployment/cert-manager-webhook -n cert-manager --timeout=120s

echo -e "${BLUE}Step 3/7: Creating OpenTelemetry namespace...${NC}"
kubectl create namespace opentelemetry --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 4/7: Creating Dash0 secrets for OpenTelemetry collector...${NC}"
kubectl create secret generic dash0-secrets \
    --from-literal=dash0-authorization-token="$DASH0_AUTH_TOKEN" \
    --from-literal=dash0-grpc-hostname="$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" \
    --from-literal=dash0-grpc-port="$DASH0_ENDPOINT_OTLP_GRPC_PORT" \
    --namespace=opentelemetry \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Step 5/7: Installing OpenTelemetry Operator...${NC}"
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator \
    --set manager.extraArgs="{--enable-go-instrumentation}" \
    --set "manager.collectorImage.repository=otel/opentelemetry-collector-k8s" \
    --namespace opentelemetry

echo -e "${BLUE}Waiting for OpenTelemetry operator to be ready...${NC}"
kubectl wait --for=condition=available deployment/opentelemetry-operator -n opentelemetry --timeout=120s

echo -e "${BLUE}Step 6/7: Installing OpenTelemetry Collectors...${NC}"
echo "  - DaemonSet collector"
helm upgrade --install otel-collector-ds open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-daemonset.yaml"

echo "  - Deployment collector"
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-deployment.yaml"

echo -e "${BLUE}Step 7/7: Deploying Java Auto-Instrumentation...${NC}"

# Wait for webhook service to be ready
echo "Waiting for OpenTelemetry operator webhook service..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-operator -n opentelemetry --timeout=120s

# Give webhook a moment to fully initialize
sleep 10

kubectl apply -f "${PROJECT_ROOT}/instrumentation/"

echo -e "${BLUE}Waiting for collectors to be ready...${NC}"
kubectl wait --for=condition=available deployment/otel-collector-opentelemetry-collector -n opentelemetry --timeout=120s

echo -e "${GREEN}✅ OpenTelemetry stack installed successfully!${NC}"
echo ""
echo "cert-manager components:"
kubectl get pods -n cert-manager
echo ""
echo "OpenTelemetry operator:"
kubectl get pods -n opentelemetry -l app.kubernetes.io/name=opentelemetry-operator
echo ""
echo "OpenTelemetry collectors:"
kubectl get pods -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector
echo ""
echo "Dash0 secrets:"
kubectl get secrets -n opentelemetry dash0-secrets
echo ""
echo "Next step: Run ./scripts/04_deploy_databases.sh (if not done) then ./scripts/06_deploy_services.sh"