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
echo "  • RabbitMQ with producer/consumer services"
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
echo -e "${BLUE}1/6 Setting up Kind cluster...${NC}"
${SCRIPT_DIR}/scripts/01_setup_kind.sh

echo -e "\n${BLUE}2/6 Setting up RabbitMQ...${NC}"
${SCRIPT_DIR}/scripts/02_setup_rabbitmq.sh

echo -e "\n${BLUE}3/6 Installing OpenTelemetry...${NC}"
${SCRIPT_DIR}/scripts/03_install_otel.sh

echo -e "\n${BLUE}4/6 Installing KEDA...${NC}"
${SCRIPT_DIR}/scripts/04_install_keda.sh

echo -e "\n${BLUE}5/6 Deploying applications...${NC}"
${SCRIPT_DIR}/scripts/05_deploy_apps.sh

echo -e "\n${BLUE}6/6 Configuring auto-scaling...${NC}"
${SCRIPT_DIR}/scripts/06_configure_scaling.sh

# Summary
echo ""
echo -e "${GREEN}✅ Setup Complete${NC}"
echo ""
echo "Test auto-scaling:"
echo "  ./scripts/generate_load.sh (for HTTP-based scaling)"
echo "  curl -X POST http://localhost:30001/publish -d '{\"message\": \"Test\"}' (for RabbitMQ-based scaling)"
echo ""
echo "Watch pods scale:"
echo "  kubectl get pods -n keda-demo -w"
echo ""
echo "Cleanup:"
echo "  ./01_cleanup.sh"