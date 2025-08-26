#!/bin/bash

# Setup Kind cluster with local registry
# This script creates a Kind cluster with a local Docker registry for development
# Based on the official Kind documentation: https://kind.sigs.k8s.io/docs/user/local-registry/

set -e

CLUSTER_NAME="${CLUSTER_NAME:-dapr-demo}"
REGISTRY_NAME="${REGISTRY_NAME:-kind-registry}"
REGISTRY_PORT="${REGISTRY_PORT:-5001}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Setting up Kind cluster with local registry${NC}"
echo "================================================"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists kind; then
    echo -e "${RED}❌ Kind is not installed. Please install Kind first.${NC}"
    echo "Visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if Kind cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}ℹ️  Cluster ${CLUSTER_NAME} already exists${NC}"
    echo -n "Do you want to recreate it? (y/n): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting existing cluster...${NC}"
        kind delete cluster --name="${CLUSTER_NAME}"
    else
        echo "Using existing cluster..."
        # Still need to ensure registry is connected
        if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
            docker network connect "kind" "${REGISTRY_NAME}" || true
        fi
        exit 0
    fi
fi

echo -e "${BLUE}Step 1/5: Creating local registry...${NC}"
# Create registry container unless it already exists
if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)" != 'true' ]; then
    docker run \
        -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --network bridge --name "${REGISTRY_NAME}" \
        registry:2
    echo -e "${GREEN}✅ Local registry started on port ${REGISTRY_PORT}${NC}"
else
    echo -e "${GREEN}✅ Local registry already running${NC}"
fi

echo -e "${BLUE}Step 2/5: Creating Kind cluster...${NC}"
# Create kind cluster with containerd registry config dir enabled
cat <<EOF | kind create cluster --name="${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 31000
    hostPort: 31000
    protocol: TCP
    listenAddress: "127.0.0.1"
  - containerPort: 31672
    hostPort: 31672
    protocol: TCP
    listenAddress: "127.0.0.1"
- role: worker
- role: worker
EOF

echo -e "${GREEN}✅ Kind cluster '${CLUSTER_NAME}' created${NC}"

echo -e "${BLUE}Step 3/5: Configuring registry access in cluster nodes...${NC}"
# Add the registry config to the nodes
# This is necessary because localhost resolves to loopback addresses that are
# network-namespace local.
# In other words: localhost in the container is not localhost on the host.
#
# We want a consistent name that works from both ends, so we tell containerd to
# alias localhost:${REGISTRY_PORT} to the registry container when pulling images
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${REGISTRY_PORT}"
for node in $(kind get nodes --name="${CLUSTER_NAME}"); do
    docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
    cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${REGISTRY_NAME}:5000"]
EOF
done

echo -e "${BLUE}Step 4/5: Connecting registry to cluster network...${NC}"
# Connect the registry to the cluster network if not already connected
# This allows kind to bootstrap the network but ensures they're on the same network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
    docker network connect "kind" "${REGISTRY_NAME}"
fi

echo -e "${BLUE}Step 5/5: Documenting local registry...${NC}"
# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo -e "${GREEN}✅ Cluster setup complete!${NC}"
echo ""
echo "Cluster: ${CLUSTER_NAME}"
echo "Registry: localhost:${REGISTRY_PORT}"
echo "Nodes: $(kind get nodes --name="${CLUSTER_NAME}" | wc -l) (1 control-plane + 2 workers)"
echo ""
echo -e "${YELLOW}📋 Port Mappings:${NC}"
echo "  Frontend (NodePort):     localhost:31000"
echo "  RabbitMQ Management:     localhost:31672"
echo ""
echo "Next step: Run ./scripts/02_install_dapr.sh"