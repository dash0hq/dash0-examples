#!/bin/bash

# Install KEDA in the cluster

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Installing KEDA...${NC}"

# Add KEDA Helm repo
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Install or upgrade KEDA
echo -e "${YELLOW}Installing/upgrading KEDA...${NC}"
helm upgrade --install keda kedacore/keda \
    --namespace keda \
    --create-namespace \
    --set prometheus.operator.enabled=true \
    --set prometheus.operator.port=8080 \
    --set prometheus.metricServer.enabled=true \
    --set prometheus.metricServer.port=9090 \
    --wait

# Wait for KEDA to be ready
echo "Waiting for KEDA pods to be ready..."
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=keda-operator \
    -n keda \
    --timeout=120s

kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=keda-operator-metrics-apiserver \
    -n keda \
    --timeout=120s

echo -e "${GREEN}✅ KEDA installed successfully${NC}"

# Show KEDA pods
echo ""
echo "KEDA pods:"
kubectl get pods -n keda