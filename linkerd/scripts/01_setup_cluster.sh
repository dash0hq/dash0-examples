#!/bin/bash
# Setup Kind cluster for Linkerd demo
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "Setting up Kind cluster for Linkerd demo"

# Check prerequisites
for cmd in kind kubectl helm; do
    command -v $cmd &>/dev/null || { echo "Error: $cmd is not installed"; exit 1; }
done

# Handle existing cluster
if kind get clusters 2>/dev/null | grep -q "linkerd-demo"; then
    echo "Cluster 'linkerd-demo' already exists."
    read -p "Delete and recreate? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && kind delete cluster --name linkerd-demo || { kubectl config use-context kind-linkerd-demo; exit 0; }
fi

kind create cluster --config "${PROJECT_ROOT}/kind/cluster.yaml"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "Kind cluster created successfully!"
kubectl get nodes
