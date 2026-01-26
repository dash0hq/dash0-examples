#!/bin/bash
# Install OpenLIT Platform (UI + backend)
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "Installing OpenLIT Platform (UI + Backend)"

kubectl cluster-info &>/dev/null || { echo "Error: Cannot connect to cluster"; exit 1; }

echo "Adding Helm repository..."
helm repo add openlit https://openlit.github.io/helm/ >/dev/null
helm repo update >/dev/null

echo "Installing OpenLIT platform..."
helm upgrade --install openlit openlit/openlit \
    --create-namespace \
    --namespace openlit \
    --timeout 180s >/dev/null

echo "Waiting for OpenLIT platform to be ready..."
kubectl rollout status statefulset/openlit -n openlit --timeout=300s
kubectl rollout status statefulset/openlit-db -n openlit --timeout=300s

echo ""
echo "OpenLIT Platform installed!"
echo "  - UI: kubectl port-forward svc/openlit -n openlit 3000:3000"
echo "  - OTLP endpoint: openlit.openlit.svc.cluster.local:4318"
echo ""
kubectl get pods -n openlit
