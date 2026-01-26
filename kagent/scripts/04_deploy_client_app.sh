#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"
REPO_ROOT="$( cd "${PROJECT_ROOT}/.." && pwd )"

# Load environment variables
if [ -f "${REPO_ROOT}/.env" ]; then
    source "${REPO_ROOT}/.env"
else
    echo "Error: .env file not found at ${REPO_ROOT}/.env"
    exit 1
fi

echo "Deploying kagent agents, MCP server, and LangChain client app"

# Create Dash0 MCP token secret
echo "Creating Dash0 MCP token secret..."
kubectl create secret generic dash0-mcp-token \
    --from-literal=token="Bearer ${DASH0_MCP_TOKEN}" \
    --namespace=kagent \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy the Dash0 MCP server
echo "Deploying Dash0 MCP server..."
kubectl apply -f "${PROJECT_ROOT}/mcp-dash0.yaml"

# Wait for MCP server to discover tools
echo "Waiting for MCP server to discover tools..."
for i in {1..30}; do
    ACCEPTED=$(kubectl get remotemcpserver dash0-mcp -n kagent -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}' 2>/dev/null || echo "False")
    TOOL_COUNT=$(kubectl get remotemcpserver dash0-mcp -n kagent -o jsonpath='{.status.discoveredTools}' 2>/dev/null | jq 'length' 2>/dev/null || echo "0")

    if [ "$ACCEPTED" = "True" ] && [ "$TOOL_COUNT" -gt "0" ]; then
        echo "MCP server ready with $TOOL_COUNT tools discovered"
        break
    fi

    if [ $i -eq 30 ]; then
        echo "Warning: MCP server not fully ready after 30 seconds, continuing anyway..."
    fi

    sleep 1
done

# Deploy the observability agent
echo "Creating observability agent..."
kubectl apply -f "${PROJECT_ROOT}/agent-observability.yaml"

# Build and deploy client app
echo "Building LangChain client app Docker image..."
docker build -t kagent-client-app:latest "${PROJECT_ROOT}/client-app"

echo "Loading image into Kind cluster..."
kind load docker-image kagent-client-app:latest --name kagent-demo

echo "Deploying client app..."
kubectl apply -f "${PROJECT_ROOT}/client-app/deployment.yaml"

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/kagent-client-app -n kagent --timeout=120s

echo "Client app, agents, and MCP server deployed successfully!"
