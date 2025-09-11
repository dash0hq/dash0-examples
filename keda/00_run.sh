#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}KEDA Auto-scaling Demo with Dash0${NC}"
echo "=================================="
echo ""
echo "This will deploy:"
echo "  • Kind cluster with KEDA"
echo "  • OpenTelemetry Collector → Dash0"
echo "  • Sample app with custom metrics"
echo "  • Auto-scaling based on Dash0 metrics"
echo ""

# Check for .env file
if [ ! -f "${SCRIPT_DIR}/../.env" ]; then
    echo "Error: .env file not found"
    echo "Copy .env.template to .env and add your Dash0 credentials"
    exit 1
fi

# Load environment variables
export $(cat ${SCRIPT_DIR}/../.env | grep -v '^#' | xargs)

# Make scripts executable
chmod +x ${SCRIPT_DIR}/scripts/*.sh

# Run setup steps
echo -e "${BLUE}1/4 Setting up Kind cluster...${NC}"
${SCRIPT_DIR}/scripts/01_setup_kind.sh

echo -e "\n${BLUE}2/4 Installing KEDA...${NC}"
${SCRIPT_DIR}/scripts/02_install_keda.sh

echo -e "\n${BLUE}3/4 Deploying application...${NC}"
${SCRIPT_DIR}/scripts/03_deploy_app.sh

echo -e "\n${BLUE}4/4 Configuring auto-scaling...${NC}"
${SCRIPT_DIR}/scripts/04_configure_scaling.sh

# Summary
echo ""
echo -e "${GREEN}✅ Setup Complete${NC}"
echo ""
echo "Test auto-scaling:"
echo "  ./scripts/generate_load.sh"
echo ""
echo "Watch pods scale:"
echo "  kubectl get pods -n keda-demo -w"
echo ""
echo "Cleanup:"
echo "  ./01_cleanup.sh"