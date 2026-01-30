#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$PROJECT_DIR")"

# Load environment variables from root .env file
if [ -f "$ROOT_DIR/.env" ]; then
  export $(cat "$ROOT_DIR/.env" | grep -v '^#' | xargs)
else
  echo "Error: $ROOT_DIR/.env file not found"
  echo "Please create a .env file in the repository root with:"
  echo "  DASH0_AUTH_TOKEN=Bearer auth_your_token_here"
  echo "  DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=ingress.eu-west-1.aws.dash0.com"
  echo "  DASH0_ENDPOINT_OTLP_GRPC_PORT=4317"
  exit 1
fi

echo "Installing OpenTelemetry Collector..."

# Create namespace
kubectl create namespace opentelemetry --dry-run=client -o yaml | kubectl apply -f -

# Create secret for Dash0 credentials
kubectl create secret generic dash0-secrets \
  --from-literal=dash0-authorization-token="$DASH0_AUTH_TOKEN" \
  --from-literal=dash0-grpc-hostname="$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" \
  --from-literal=dash0-grpc-port="$DASH0_ENDPOINT_OTLP_GRPC_PORT" \
  -n opentelemetry \
  --dry-run=client -o yaml | kubectl apply -f -

# Install OpenTelemetry Operator
echo "Installing OpenTelemetry Operator..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace opentelemetry \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.autoGenerateCert.enabled=true \
  --wait \
  --timeout 5m

# Install OpenTelemetry Collector
echo "Installing OpenTelemetry Collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace opentelemetry \
  -f "$PROJECT_DIR/collector/otel-collector-deployment.yaml" \
  --wait \
  --timeout 5m

# Apply telemetry policy for tracing
echo "Applying telemetry policy..."
kubectl apply -f "$PROJECT_DIR/agentgateway/telemetry-referencegrant.yaml"
kubectl apply -f "$PROJECT_DIR/agentgateway/telemetry-policy.yaml"

echo "OpenTelemetry Collector installed successfully!"
