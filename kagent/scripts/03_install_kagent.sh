#!/bin/bash
# Install kagent with tracing enabled
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "Installing kagent"

kubectl cluster-info &>/dev/null || { echo "Error: Cannot connect to cluster"; exit 1; }

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

echo "Applying ModelConfig for local Ollama..."
kubectl apply -f "${PROJECT_ROOT}/modelconfig.yaml"

echo "kagent installed!"
kubectl get pods -n kagent
