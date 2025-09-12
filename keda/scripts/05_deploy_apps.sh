#!/bin/bash

# Deploy all applications for KEDA scaling demo

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="${SCRIPT_DIR}/../services/http-test"

echo -e "${GREEN}Deploying all applications...${NC}"

# Create namespace
kubectl create namespace keda-demo --dry-run=client -o yaml | kubectl apply -f -

# Build and deploy HTTP application
echo -e "${BLUE}Building HTTP application image...${NC}"
docker build -t http-app:v1 "${APP_DIR}"
kind load docker-image http-app:v1 --name keda-demo

echo -e "${BLUE}Deploying HTTP application...${NC}"
kubectl apply -f "${SCRIPT_DIR}/../manifests/http-deployment.yaml"

# Build RabbitMQ services images
echo -e "${BLUE}Building RabbitMQ producer and consumer images...${NC}"
cd "${SCRIPT_DIR}/.."
docker build -t rabbitmq-producer:v1 services/producer/
docker build -t rabbitmq-consumer:v1 services/consumer/
kind load docker-image rabbitmq-producer:v1 --name keda-demo
kind load docker-image rabbitmq-consumer:v1 --name keda-demo
echo "RabbitMQ images built and loaded successfully!"

echo -e "${BLUE}Deploying RabbitMQ producer and consumer...${NC}"
kubectl apply -f manifests/producer-deployment.yaml
kubectl apply -f manifests/consumer-deployment.yaml

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/http-app -n keda-demo --timeout=120s
kubectl rollout status deployment/rabbitmq-producer -n keda-demo --timeout=120s
kubectl rollout status deployment/rabbitmq-consumer -n keda-demo --timeout=120s

echo -e "${GREEN}✅ All applications deployed successfully${NC}"