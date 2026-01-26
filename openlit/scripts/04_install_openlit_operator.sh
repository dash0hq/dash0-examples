#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "Installing OpenLIT Operator"

# Add OpenLIT Helm repo
helm repo add openlit https://openlit.github.io/helm/
helm repo update

# Install OpenLIT Operator (only the operator, not the platform/UI)
helm upgrade --install openlit-operator openlit/openlit-operator \
    --create-namespace \
    --namespace openlit \
    --timeout 120s

kubectl rollout status deployment/openlit-operator -n openlit --timeout=120s

# Create demo namespace
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

# Create AutoInstrumentation CR that sends to our OTel Collector
kubectl apply -f "${PROJECT_ROOT}/k8s/auto-instrumentation.yaml"

echo "OpenLIT Operator installed!"
kubectl get pods -n openlit
