#!/bin/bash
# Install OpenTelemetry Collector for OpenLIT observability
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"
REPO_ROOT="$( cd "${PROJECT_ROOT}/.." && pwd )"

echo "Installing OpenTelemetry Collector"

kubectl cluster-info &>/dev/null || { echo "Error: Cannot connect to cluster"; exit 1; }

# Load environment
if [ -f "${REPO_ROOT}/.env" ]; then
    source "${REPO_ROOT}/.env"
else
    echo "Error: .env file not found in repository root."
    echo "Required: DASH0_AUTH_TOKEN, DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME, DASH0_ENDPOINT_OTLP_GRPC_PORT"
    exit 1
fi

echo "Adding Helm repository..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null
helm repo update >/dev/null

echo "Creating namespace and secrets..."
kubectl create namespace opentelemetry --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create secret generic dash0-secrets \
    --from-literal=dash0-authorization-token="${DASH0_AUTH_TOKEN}" \
    --from-literal=dash0-grpc-hostname="${DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME}" \
    --from-literal=dash0-grpc-port="${DASH0_ENDPOINT_OTLP_GRPC_PORT:-4317}" \
    --namespace=opentelemetry \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null

echo "Installing collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f "${PROJECT_ROOT}/collector/otel-collector-deployment.yaml" \
    --timeout 120s >/dev/null

kubectl rollout status deployment/otel-collector-opentelemetry-collector -n opentelemetry --timeout=120s

echo "OpenTelemetry Collector installed!"
kubectl get pods -n opentelemetry
