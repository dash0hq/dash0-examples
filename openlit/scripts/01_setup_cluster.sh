#!/bin/bash
set -e

echo "Setting up Kind cluster for OpenLIT demo"

# Create Kind cluster
cat <<EOF | kind create cluster --name openlit-demo --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
EOF

# Wait for cluster to be ready
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo "Kind cluster created successfully!"
kubectl get nodes
