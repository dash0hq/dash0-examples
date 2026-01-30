#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Creating Kind cluster for agentgateway demo..."
kind create cluster --config "$PROJECT_DIR/kind/cluster.yaml" --wait 5m

echo "Kind cluster created successfully!"
kubectl cluster-info --context kind-agentgateway-demo
