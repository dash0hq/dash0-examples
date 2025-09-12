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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
helm upgrade --install keda kedacore/keda \
    --namespace keda \
    --create-namespace \
    --values "${SCRIPT_DIR}/../keda/values.yaml" \
    --wait

echo -e "${GREEN}✅ KEDA installed successfully with OpenTelemetry metrics enabled${NC}"