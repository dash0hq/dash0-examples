#!/bin/bash

# Run script for OpenLLMetry demo
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${RED}Virtual environment not found!${NC}"
    echo "Please run ./00_setup.sh first"
    exit 1
fi

# Check if collector is running
if ! docker ps | grep -q openllmetry-otel-collector; then
    echo -e "${RED}OpenTelemetry Collector is not running!${NC}"
    echo "Please run ./00_setup.sh first"
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

# Load environment variables
if [ -f "../.env" ]; then
    set -a
    source ../.env
    set +a
fi

echo -e "${GREEN}Running OpenLLMetry Demo${NC}"
echo "=========================="
echo ""

# Run the demo
python app.py

echo ""
echo -e "${GREEN}Demo execution complete!${NC}"
