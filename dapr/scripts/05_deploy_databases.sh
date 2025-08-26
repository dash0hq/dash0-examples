#!/bin/bash

# Deploy database infrastructure
# This script deploys PostgreSQL and RabbitMQ

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🗄️  Deploying Database Infrastructure${NC}"
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

# Deploy RabbitMQ
echo -e "\n${BLUE}Deploying RabbitMQ...${NC}"
kubectl apply -f "${PROJECT_ROOT}/infrastructure/rabbitmq/rabbitmq.yaml"

# Wait for databases to be ready
echo -e "\n${YELLOW}Waiting for databases to be ready...${NC}"

echo -n "Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n dapr-demo --timeout=120s 2>/dev/null || {
    echo -e "\n${YELLOW}⚠️  PostgreSQL is taking longer than expected to start${NC}"
}
echo -e " ${GREEN}✓${NC}"

echo -n "Waiting for RabbitMQ..."
kubectl wait --for=condition=ready pod -l app=rabbitmq -n dapr-demo --timeout=120s 2>/dev/null || {
    echo -e "\n${YELLOW}⚠️  RabbitMQ is taking longer than expected to start${NC}"
}
echo -e " ${GREEN}✓${NC}"

echo -e "\n${GREEN}✅ Database infrastructure deployed!${NC}"
echo ""
echo "Deployed databases:"
echo "  - PostgreSQL (for todo state store)"
echo "  - RabbitMQ (for pub/sub messaging)"
echo ""
echo "Database status:"
kubectl get pods -n dapr-demo -l 'app in (postgres, rabbitmq)'
echo ""
echo "RabbitMQ Management UI will be available at: http://localhost:31672"
echo "  Username: guest"
echo "  Password: guest"
echo ""
echo "Next step: Run ./scripts/05_deploy_dapr_components.sh"