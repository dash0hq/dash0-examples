#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"
REPO_ROOT="$( cd "${PROJECT_ROOT}/.." && pwd )"

echo "Deploying sample app"

# Source .env for Anthropic API key
if [ -f "${REPO_ROOT}/.env" ]; then
    source "${REPO_ROOT}/.env"
else
    echo "Error: .env file not found in repository root."
    exit 1
fi

# Build Docker image
echo "Building Docker image..."
docker build -t python-openlit-demo-app:latest "${PROJECT_ROOT}/app"

# Load image into Kind cluster
echo "Loading image into Kind cluster..."
kind load docker-image python-openlit-demo-app:latest --name openlit-demo

# Create namespace
kubectl apply -f "${PROJECT_ROOT}/app/deployment.yaml"

# Create Anthropic API key secret
echo "Creating Anthropic API key secret..."
kubectl create secret generic anthropic-api-key \
    --from-literal=ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
    --namespace=demo \
    --dry-run=client -o yaml | kubectl apply -f -

# Patch deployment to use the secret
kubectl patch deployment openlit-demo-app -n demo --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name": "ANTHROPIC_API_KEY",
      "valueFrom": {
        "secretKeyRef": {
          "name": "anthropic-api-key",
          "key": "ANTHROPIC_API_KEY"
        }
      }
    }
  }
]'

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/openlit-demo-app -n demo --timeout=120s

echo "App deployed successfully!"
kubectl get pods -n demo
