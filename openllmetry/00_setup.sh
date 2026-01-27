#!/bin/bash

# Setup script for OpenLLMetry demo
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up OpenLLMetry Demo${NC}"
echo "===================================="
echo ""

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

if [ -z "$DASH0_AUTH_TOKEN" ]; then
    echo -e "${RED}DASH0_AUTH_TOKEN not set in .env file${NC}"
    echo "Please add your Dash0 auth token to ../.env"
    exit 1
fi

echo -e "${GREEN}Environment configured${NC}"

# Create virtual environment with uv
echo -e "${BLUE}Creating virtual environment with uv...${NC}"
cd "$SCRIPT_DIR"
uv venv

# Activate virtual environment and install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
source .venv/bin/activate
uv pip install -r requirements.txt

# Start OpenTelemetry Collector
echo -e "${BLUE}Starting OpenTelemetry Collector...${NC}"
docker-compose up -d

# Wait for collector to be ready
echo -e "${BLUE}Waiting for collector to be ready...${NC}"
sleep 3

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "To run the demo:"
echo "  ./run.sh"
echo ""
echo "To cleanup:"
echo "  ./01_cleanup.sh"
