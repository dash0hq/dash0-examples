#!/bin/bash
# Install kagent with tracing enabled
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"
REPO_ROOT="$( cd "${PROJECT_ROOT}/.." && pwd )"

echo "Installing kagent"

kubectl cluster-info &>/dev/null || { echo "Error: Cannot connect to cluster"; exit 1; }

# Source .env file from repository root
if [ -f "${REPO_ROOT}/.env" ]; then
    source "${REPO_ROOT}/.env"
else
    echo "Error: .env file not found in repository root."
    exit 1
fi

echo "Creating kagent namespace..."
kubectl create namespace kagent --dry-run=client -o yaml | kubectl apply -f -

echo "Creating Anthropic API key secret..."
kubectl create secret generic anthropic-api-key \
    --from-literal=api-key="${ANTHROPIC_API_KEY}" \
    --namespace=kagent \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Installing kagent CRDs..."
helm upgrade --install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --namespace kagent \
    --create-namespace

echo "Installing kagent..."
helm upgrade --install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace kagent \
    -f "${PROJECT_ROOT}/values.yaml" \
    --timeout 120s

kubectl rollout status deployment/kagent-controller -n kagent --timeout=120s
kubectl rollout status deployment/kagent-ui -n kagent --timeout=120s

echo "Removing default agents (not needed for demo)..."
kubectl delete agents --all -n kagent --ignore-not-found=true

echo "kagent installed!"
kubectl get pods -n kagent
