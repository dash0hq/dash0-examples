#!/usr/bin/env bash

set -eo pipefail

# Source environment variables from .env file
if [ -f "../.env" ]; then
    source ../.env
else
    echo "Error: .env file not found. Please copy .env.template to .env and configure your settings."
    exit 1
fi

VERSION=${VERSION:-v1}
CLUSTER_NAME=${CLUSTER_NAME:-java-instrumentation}

echo "Setting up Kubernetes cluster for Java instrumentation example..."

# Create kind cluster
echo "Creating kind cluster: $CLUSTER_NAME"
kind create cluster --name=$CLUSTER_NAME --config ./kubernetes/kind/multi-node.yaml
kubectl create namespace opentelemetry

# Create Dash0 secrets for OpenTelemetry collector
echo "Creating Dash0 secrets..."
kubectl create secret generic dash0-secrets \
    --from-literal=dash0-authorization-token="$DASH0_AUTH_TOKEN" \
    --from-literal=dash0-grpc-hostname="$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" \
    --from-literal=dash0-grpc-port="$DASH0_ENDPOINT_OTLP_GRPC_PORT" \
    --namespace=opentelemetry

# Build and load images
echo "Building Docker images..."
docker build -f ./frontend/Dockerfile -t frontend:$VERSION ./frontend
docker build -f ./validation-service/Dockerfile.k8s -t validation-service:$VERSION ./validation-service
docker build -f ./todo-service/Dockerfile.k8s -t todo-service:$VERSION ./todo-service

echo "Loading images into kind cluster..."
kind load docker-image --name $CLUSTER_NAME frontend:$VERSION
kind load docker-image --name $CLUSTER_NAME validation-service:$VERSION
kind load docker-image --name $CLUSTER_NAME todo-service:$VERSION

# Deploy infrastructure
echo "Deploying MySQL..."
helm install my-mysql bitnami/mysql \
    --set auth.rootPassword=mysecretPassword \
    --set auth.database=todo \
    --set auth.username=todo \
    --set auth.password=mysecretPassword

echo "Deploying Jaeger..."
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm upgrade --install jaeger jaegertracing/jaeger --values ./kubernetes/jaeger/values.yaml

echo "Deploying Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install prometheus prometheus-community/prometheus --values ./kubernetes/prometheus/values.yaml

echo "Deploying OpenSearch..."
helm repo add opensearch https://opensearch-project.github.io/helm-charts
helm upgrade --install opensearch opensearch/opensearch -f ./kubernetes/opensearch/values.yaml
helm upgrade --install opensearch-dashboards opensearch/opensearch-dashboards -f ./kubernetes/opensearch/dashboard-values.yaml

echo "Deploying cert-manager..."
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true

echo "Deploying OpenTelemetry Operator..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator --set "manager.collectorImage.repository=otel/opentelemetry-collector-k8s" --namespace opentelemetry --create-namespace

echo "Deploying OpenTelemetry Collector..."
helm upgrade --install otel-collector-deployment open-telemetry/opentelemetry-collector --namespace opentelemetry -f ./kubernetes/collector/values.yaml

echo "Waiting for OpenTelemetry operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/opentelemetry-operator -n opentelemetry

echo "Waiting for webhook to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod -l app.kubernetes.io/name=opentelemetry-operator -n opentelemetry
sleep 30

echo "Applying instrumentation..."
kubectl apply -f ./kubernetes/instrumentations/instrumentation.yaml

echo "Deploying applications..."
kubectl apply -f ./frontend/manifests/
kubectl apply -f ./validation-service/manifests/
kubectl apply -f ./todo-service/manifests/

echo "Deployment complete! Your Java instrumentation example is running on Kubernetes."
echo "Cluster name: $CLUSTER_NAME"
echo ""
echo "To delete the cluster, run: kind delete cluster --name=$CLUSTER_NAME"