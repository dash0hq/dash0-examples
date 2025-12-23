#!/bin/bash
# Cleanup script for kagent demo
set -e

echo "Cleaning up kagent demo..."

if kind get clusters 2>/dev/null | grep -q "kagent-demo"; then
    echo "Deleting Kind cluster 'kagent-demo'..."
    kind delete cluster --name kagent-demo
    echo "Cluster deleted successfully!"
else
    echo "Cluster 'kagent-demo' not found."
fi
