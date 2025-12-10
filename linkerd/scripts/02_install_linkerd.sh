#!/bin/bash
# Install Linkerd service mesh with tracing enabled
set -e

LINKERD_VERSION="edge-25.12.1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "Installing Linkerd ${LINKERD_VERSION}"

kubectl cluster-info &>/dev/null || { echo "Error: Cannot connect to cluster"; exit 1; }

# Install CLI if needed
if ! command -v linkerd &>/dev/null || [[ "$(linkerd version --client --short 2>/dev/null)" != *"edge-25"* ]]; then
    echo "Installing Linkerd CLI..."
    curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | LINKERD2_VERSION=${LINKERD_VERSION} sh
    export PATH=$HOME/.linkerd2/bin:$PATH
fi

command -v linkerd &>/dev/null || { echo "Error: Linkerd CLI not in PATH. Run: export PATH=\$HOME/.linkerd2/bin:\$PATH"; exit 1; }

echo "Installing Gateway API CRDs..."
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml >/dev/null

echo "Running pre-checks..."
linkerd check --pre

echo "Installing Linkerd CRDs..."
linkerd install --crds | kubectl apply -f - >/dev/null

echo "Installing Linkerd control plane..."
linkerd install -f "${PROJECT_ROOT}/linkerd-values.yaml" | kubectl apply -f - >/dev/null

echo "Waiting for Linkerd..."
linkerd check

echo "Linkerd installed successfully!"
