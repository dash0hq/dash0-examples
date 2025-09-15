#!/bin/bash

# Setup Kind cluster for KEDA demo

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLUSTER_NAME="keda-demo"

echo -e "${GREEN}Setting up Kind cluster: ${CLUSTER_NAME}${NC}"

# Check if cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}Cluster ${CLUSTER_NAME} already exists. Skipping creation.${NC}"
else
    # Create Kind cluster configuration
    cat <<EOF > /tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
EOF

    # Create cluster
    kind create cluster --config=/tmp/kind-config.yaml
    
    # Clean up temp file
    rm /tmp/kind-config.yaml
    
    echo -e "${GREEN}✅ Kind cluster created successfully${NC}"
fi

# Set kubectl context
kubectl cluster-info --context kind-${CLUSTER_NAME}

echo -e "${GREEN}✅ Kubectl context set to kind-${CLUSTER_NAME}${NC}"