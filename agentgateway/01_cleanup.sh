#!/bin/bash
set -e

echo "Cleaning up agentgateway demo..."

# Delete the Kind cluster
kind delete cluster --name agentgateway-demo

echo "Cleanup complete!"
