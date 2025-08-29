#!/bin/bash

# Deploy Dapr components
# This script deploys all Dapr components (state stores, pubsub, configuration)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎯 Deploying Dapr Components${NC}"
echo "=============================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_kind.sh first.${NC}"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace dapr-demo &>/dev/null; then
    echo -e "${RED}❌ Namespace 'dapr-demo' does not exist. Please run 04_deploy_databases.sh first.${NC}"
    exit 1
fi

# Check if Dapr is installed
if ! kubectl get namespace dapr-system &>/dev/null; then
    echo -e "${RED}❌ Dapr is not installed. Please run 02_install_dapr.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Deploying Dapr components...${NC}"

# Deploy tracing configuration
echo "  - Tracing configuration"
kubectl apply -f "${PROJECT_ROOT}/components/tracing.yaml"

# Deploy state stores
echo "  - Todo state store (PostgreSQL)"
kubectl apply -f "${PROJECT_ROOT}/components/todo-statestore.yaml"

# Deploy pubsub
echo "  - PubSub component (RabbitMQ)"
kubectl apply -f "${PROJECT_ROOT}/components/pubsub.yaml"


echo -e "\n${GREEN}✅ Dapr components deployed!${NC}"
echo ""
echo "Deployed components:"
echo "  State Stores:"
echo "    - todo-statestore (PostgreSQL)"
echo "  PubSub:"
echo "    - todo-pubsub (RabbitMQ)"
echo "  Configuration:"
echo "    - tracing (OpenTelemetry)"
echo ""
echo "View components:"
echo "  kubectl get components -n dapr-demo"
echo ""
echo "Next step: Run ./scripts/06_deploy_services.sh"