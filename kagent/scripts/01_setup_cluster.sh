#!/bin/bash
# Setup Kind cluster for kagent demo
set -e

echo "Setting up Kind cluster for kagent demo"

# Check prerequisites
for cmd in kind kubectl helm; do
    command -v $cmd &>/dev/null || { echo "Error: $cmd is not installed"; exit 1; }
done

# Handle existing cluster
if kind get clusters 2>/dev/null | grep -q "kagent-demo"; then
    echo "Cluster 'kagent-demo' already exists."
    read -p "Delete and recreate? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && kind delete cluster --name kagent-demo || { kubectl config use-context kind-kagent-demo; exit 0; }
fi

kind create cluster --name kagent-demo
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "Kind cluster created successfully!"
kubectl get nodes
