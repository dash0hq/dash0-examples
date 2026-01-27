#!/bin/bash

# Run FastAPI app with auto-instrumentation
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

echo -e "${GREEN}Starting FastAPI with Auto-Instrumentation${NC}"
echo "=============================================="
echo ""
echo "Server will start on http://localhost:8080"
echo "API docs available at http://localhost:8080/docs"
echo ""
echo "Example request:"
echo '  curl -X POST http://localhost:8080/analyze \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"query": "This is amazing!"}'"'"
echo ""

# Run with OpenTelemetry auto-instrumentation
export OTEL_SERVICE_NAME="openllmetry-fastapi-demo"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"

opentelemetry-instrument \
    --traces_exporter otlp \
    --metrics_exporter none \
    --service_name openllmetry-fastapi-demo \
    uvicorn app_fastapi:app --host 0.0.0.0 --port 8080
