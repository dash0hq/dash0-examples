#!/bin/bash

# Configure KEDA scaling with Dash0 metrics

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo -e "${GREEN}Configuring KEDA scaling with Dash0 metrics...${NC}"

# Load environment variables
if [ -f "${SCRIPT_DIR}/../../.env" ]; then
    export $(cat ${SCRIPT_DIR}/../../.env | grep -v '^#' | xargs)
    # Ensure DASH0_API_URL is exported for envsubst
    export DASH0_API_URL
fi

# Check for required environment variables
if [ -z "$DASH0_AUTH_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  DASH0_AUTH_TOKEN not set in .env file${NC}"
    echo "Please set your Dash0 credentials in the .env file"
    exit 1
fi

# Create secret for Dash0 authentication
echo -e "${BLUE}Creating secret for Dash0 authentication...${NC}"
kubectl create secret generic dash0-auth-secret \
    --from-literal=authToken="${DASH0_AUTH_TOKEN}" \
    --namespace=keda-demo \
    --dry-run=client -o yaml | kubectl apply -f -

# Apply TriggerAuthentication
echo -e "${BLUE}Creating TriggerAuthentication for Dash0...${NC}"
kubectl apply -f "${PROJECT_ROOT}/manifests/keda/trigger-authentication.yaml"

# Deploy ScaledObject configuration
echo -e "${BLUE}Creating ScaledObject with OpenTelemetry metrics from Dash0...${NC}"
envsubst < "${PROJECT_ROOT}/manifests/keda/scaled-object.yaml" | kubectl apply -f -

echo -e "${GREEN}✅ KEDA scaling configured successfully${NC}"

# Show the ScaledObjects
echo ""
echo "ScaledObjects:"
kubectl get scaledobjects -n keda-demo

echo ""
echo "HPA created by KEDA:"
kubectl get hpa -n keda-demo