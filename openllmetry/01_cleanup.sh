#!/bin/bash

# Cleanup script for OpenLLMetry demo
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Cleaning up OpenLLMetry Demo${NC}"
echo "================================"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Stop and remove Docker containers
echo -e "${BLUE}Stopping Docker containers...${NC}"
docker-compose down

# Remove virtual environment
if [ -d ".venv" ]; then
    echo -e "${BLUE}Removing virtual environment...${NC}"
    rm -rf .venv
fi

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
