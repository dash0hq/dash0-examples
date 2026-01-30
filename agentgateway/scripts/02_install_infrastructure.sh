#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing observability infrastructure..."

# Create namespace
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add opensearch https://opensearch-project.github.io/helm-charts/ 2>/dev/null || true
helm repo update

# Install Jaeger
echo "Installing Jaeger..."
helm upgrade --install jaeger jaegertracing/jaeger \
    --namespace default \
    --version 3.4.1 \
    -f "$PROJECT_DIR/infrastructure/jaeger/values.yaml" \
    --wait \
    --timeout 5m

# Install Prometheus
echo "Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace default \
    -f "$PROJECT_DIR/infrastructure/prometheus/values.yaml" \
    --wait \
    --timeout 5m

# Install OpenSearch
echo "Installing OpenSearch..."
helm upgrade --install opensearch opensearch/opensearch \
    --namespace default \
    -f "$PROJECT_DIR/infrastructure/opensearch/opensearch-values.yaml" \
    --wait \
    --timeout 10m

echo "Infrastructure installed successfully!"
