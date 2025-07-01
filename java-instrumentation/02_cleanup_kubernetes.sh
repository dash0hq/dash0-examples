#!/usr/bin/env bash

set -eo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-java-instrumentation}

echo "Cleaning up Java instrumentation Kubernetes example..."
echo "Cluster name: $CLUSTER_NAME"

# Check if cluster exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Cluster '$CLUSTER_NAME' does not exist. Nothing to clean up."
    exit 0
fi

echo "Deleting kind cluster: $CLUSTER_NAME"
kind delete cluster --name=$CLUSTER_NAME

echo "Cleanup complete! Cluster '$CLUSTER_NAME' has been deleted."