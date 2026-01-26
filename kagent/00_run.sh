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

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for environment file
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Environment file not found at ${ENV_FILE}${NC}"
    echo "Please ensure ../.env exists with your Anthropic API key and Dash0 credentials."
    exit 1
fi

# Source the env file to check for required variables
source "$ENV_FILE"

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${RED}ANTHROPIC_API_KEY not set in .env file${NC}"
    echo "Please add your Anthropic API key to ../.env"
    exit 1
fi

if [ -z "$DASH0_MCP_TOKEN" ]; then
    echo -e "${RED}DASH0_MCP_TOKEN not set in .env file${NC}"
    echo "Please add your Dash0 MCP token to ../.env"
    exit 1
fi

echo -e "${GREEN}Environment configured${NC}"

echo -e "${BLUE}Executing setup scripts...${NC}"
echo ""

# Make scripts executable
chmod +x "${SCRIPT_DIR}/scripts"/*.sh

# Run setup scripts
echo -e "${BLUE}1/5: Setting up Kind cluster...${NC}"
"${SCRIPT_DIR}/scripts/01_setup_cluster.sh"
echo ""

echo -e "${BLUE}2/5: Installing OpenTelemetry Collector...${NC}"
"${SCRIPT_DIR}/scripts/02_install_otel.sh"
echo ""

echo -e "${BLUE}3/5: Installing kagent...${NC}"
"${SCRIPT_DIR}/scripts/03_install_kagent.sh"
echo ""

echo -e "${BLUE}4/5: Deploying MCP server and agents...${NC}"
"${SCRIPT_DIR}/scripts/04_deploy_client_app.sh"
echo ""

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${BLUE}Deployed resources:${NC}"
echo "Agents:"
kubectl get agents -n kagent
echo ""
echo "MCP Servers:"
kubectl get remotemcpservers -n kagent
echo ""
echo "Pods:"
kubectl get pods -n kagent
