#!/bin/bash

# Complete setup script for kagent demo with observability
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Kagent Demo with Observability${NC}"
echo "==========================================="
echo ""
echo "This will:"
echo "1. Create a Kind cluster"
echo "2. Install OpenTelemetry Collector (exports traces to Dash0)"
echo "3. Install kagent with tracing enabled (uses local Ollama)"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for environment file
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Environment file not found at ${ENV_FILE}${NC}"
    echo "Please copy .env.template to .env and configure it with your Dash0 credentials."
    exit 1
fi

# Check if local Ollama is running
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo -e "${RED}Ollama is not running locally${NC}"
    echo "Please start Ollama with: ollama serve"
    echo "And ensure you have a model pulled: ollama pull gpt-oss:20b"
    exit 1
fi

echo -e "${GREEN}Local Ollama detected${NC}"

echo -e "${BLUE}Executing setup scripts...${NC}"
echo ""

# Make scripts executable
chmod +x "${SCRIPT_DIR}/scripts"/*.sh

# Run setup scripts
echo -e "${BLUE}1/3: Setting up Kind cluster...${NC}"
"${SCRIPT_DIR}/scripts/01_setup_cluster.sh"
echo ""

echo -e "${BLUE}2/3: Installing OpenTelemetry Collector...${NC}"
"${SCRIPT_DIR}/scripts/02_install_otel.sh"
echo ""

echo -e "${BLUE}3/3: Installing kagent...${NC}"
"${SCRIPT_DIR}/scripts/03_install_kagent.sh"
echo ""

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Port forward to access kagent UI:"
echo "   kubectl port-forward svc/kagent-ui -n kagent 8080:8080"
echo ""
echo "2. Open the kagent web UI:"
echo "   open http://localhost:8080"
echo ""
echo "3. Check your Dash0 dashboard for traces!"
echo ""
echo -e "${BLUE}Cluster components:${NC}"
kubectl get pods -A
