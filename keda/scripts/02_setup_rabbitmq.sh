#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}Setting up RabbitMQ for KEDA demo...${NC}"

# Create namespace
echo "Creating keda-demo namespace..."
kubectl create namespace keda-demo --dry-run=client -o yaml | kubectl apply -f -

# Install RabbitMQ operator
echo "Installing RabbitMQ operator..."
kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"

# Wait for operator to be ready
echo "Waiting for RabbitMQ operator to be ready..."
kubectl wait --for=condition=Available deployment/rabbitmq-cluster-operator -n rabbitmq-system --timeout=300s

# Create RabbitMQ cluster
echo "Creating RabbitMQ cluster..."
kubectl apply -f "${SCRIPT_DIR}/../infrastructure/rabbitmq/rabbitmq-cluster.yaml"

# Wait for RabbitMQ to be ready
echo "Waiting for RabbitMQ cluster to be ready..."
kubectl wait --for=condition=AllReplicasReady rabbitmqcluster/rabbitmq -n keda-demo --timeout=300s

# RabbitMQ services will be deployed later by the app deployment script

echo -e "${GREEN}✅ RabbitMQ setup complete${NC}"
echo ""
echo "Producer API available at: http://localhost:30001"
echo "Test manual publishing: curl -X POST http://localhost:30001/publish -H 'Content-Type: application/json' -d '{\"message\": \"Test message\"}'"
echo ""
echo "Watch consumer pods scale:"
echo "  kubectl get pods -n keda-demo -l app=rabbitmq-consumer -w"