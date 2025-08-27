#!/bin/bash

# Deploy infrastructure components
# This script deploys PostgreSQL and RabbitMQ

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🏗️  Deploying Infrastructure Components${NC}"
echo "======================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please run 01_setup_kind.sh first.${NC}"
    exit 1
fi

# Create namespace if it doesn't exist
echo -e "${BLUE}Creating namespace...${NC}"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: dapr-demo
  labels:
    name: dapr-demo
EOF

# Deploy PostgreSQL
echo -e "\n${BLUE}Deploying PostgreSQL...${NC}"
kubectl apply -f "${PROJECT_ROOT}/infrastructure/postgres/postgres.yaml"

# Deploy RabbitMQ using Cluster Operator
echo -e "\n${BLUE}Installing RabbitMQ Cluster Operator...${NC}"
# Check if operator is already installed
if kubectl get deployment -n rabbitmq-system rabbitmq-cluster-operator &>/dev/null; then
    echo "RabbitMQ Cluster Operator already installed"
else
    kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"
    echo -n "Waiting for operator to be ready..."
    kubectl wait --for=condition=available --timeout=120s deployment/rabbitmq-cluster-operator -n rabbitmq-system
    echo -e " ${GREEN}✓${NC}"
fi

echo -e "\n${BLUE}Deploying RabbitMQ cluster...${NC}"
kubectl apply -f "${PROJECT_ROOT}/infrastructure/rabbitmq/rabbitmq-cluster.yaml"

# Wait for infrastructure to be ready
echo -e "\n${YELLOW}Waiting for infrastructure components to be ready...${NC}"

echo -n "Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n dapr-demo --timeout=120s 2>/dev/null || {
    echo -e "\n${YELLOW}⚠️  PostgreSQL is taking longer than expected to start${NC}"
}
echo -e " ${GREEN}✓${NC}"

echo -n "Waiting for RabbitMQ cluster..."
kubectl wait --for=condition=AllReplicasReady rabbitmqcluster/rabbitmq -n dapr-demo --timeout=120s 2>/dev/null || {
    echo -e "\n${YELLOW}⚠️  RabbitMQ cluster is taking longer than expected to start${NC}"
}
echo -e " ${GREEN}✓${NC}"

echo -e "\n${GREEN}✅ Infrastructure components deployed!${NC}"
echo ""
echo "Deployed infrastructure:"
echo "  - PostgreSQL (for todo state store)"
echo "  - RabbitMQ cluster (for pub/sub messaging)"
echo ""
echo "Infrastructure status:"
kubectl get pods -n dapr-demo -l 'app in (postgres)' 2>/dev/null
kubectl get pods -n dapr-demo -l 'app.kubernetes.io/name=rabbitmq' 2>/dev/null
echo ""
echo "RabbitMQ Management UI will be available at: http://localhost:31672"
echo "  Username: guest"
echo "  Password: guest"
echo ""
echo "Next step: Run ./scripts/05_deploy_dapr_components.sh"