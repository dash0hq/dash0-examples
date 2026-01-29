#!/bin/bash

# Install local observability stack (Jaeger, Prometheus, OpenSearch)
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔭 Installing Local Observability Stack${NC}"
echo "========================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_cluster.sh first.${NC}"
    exit 1
fi

# Create namespace for observability tools
echo -e "${BLUE}Step 1/7: Creating default namespace...${NC}"
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo -e "${BLUE}Step 2/7: Adding Helm repositories...${NC}"
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add opensearch https://opensearch-project.github.io/helm-charts/ 2>/dev/null || true
helm repo update

# Install Jaeger
echo -e "${BLUE}Step 3/7: Installing Jaeger...${NC}"
helm upgrade --install jaeger jaegertracing/jaeger \
    --namespace default \
    --version 3.4.1 \
    -f "${PROJECT_ROOT}/infrastructure/jaeger/values.yaml" \
    --wait \
    --timeout 5m

# Install Prometheus
echo -e "${BLUE}Step 4/7: Installing Prometheus...${NC}"
helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace default \
    -f "${PROJECT_ROOT}/infrastructure/prometheus/values.yaml" \
    --wait \
    --timeout 5m

# Install OpenSearch
echo -e "${BLUE}Step 5/7: Installing OpenSearch...${NC}"
helm upgrade --install opensearch opensearch/opensearch \
    --namespace default \
    -f "${PROJECT_ROOT}/infrastructure/opensearch/opensearch-values.yaml" \
    --wait \
    --timeout 10m

# Install OpenSearch Dashboards
echo -e "${BLUE}Step 6/7: Installing OpenSearch Dashboards...${NC}"
helm upgrade --install opensearch-dashboards opensearch/opensearch-dashboards \
    --namespace default \
    -f "${PROJECT_ROOT}/infrastructure/opensearch/opensearch-dashboards-values.yaml" \
    --wait \
    --timeout 5m

echo -e "${BLUE}Step 7/7: Waiting for all pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=jaeger -n default --timeout=120s || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=prometheus -n default --timeout=120s || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=opensearch -n default --timeout=180s || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=opensearch-dashboards -n default --timeout=120s || true

echo -e "${GREEN}✅ Local observability stack installed successfully!${NC}"
echo ""
echo "Installed components:"
kubectl get pods -n default -l 'app.kubernetes.io/instance in (jaeger,prometheus,opensearch,opensearch-dashboards)'
echo ""
echo "Access the UIs using port-forward:"
echo -e "${YELLOW}Jaeger UI:${NC}"
echo "  kubectl port-forward -n default svc/jaeger-query 16686:16686"
echo "  Then visit: http://localhost:16686"
echo ""
echo -e "${YELLOW}Prometheus UI:${NC}"
echo "  kubectl port-forward -n default svc/prometheus 9090:9090"
echo "  Then visit: http://localhost:9090"
echo ""
echo -e "${YELLOW}OpenSearch Dashboards:${NC}"
echo "  kubectl port-forward -n default svc/opensearch-dashboards 5601:5601"
echo "  Then visit: http://localhost:5601"
echo "  Credentials: admin / SecureP@ssw0rd123"
echo ""
