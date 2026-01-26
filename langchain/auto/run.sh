#!/bin/bash
# Run the auto-instrumented demo

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate virtual environment
source "${SCRIPT_DIR}/.venv/bin/activate"

# Set OpenTelemetry environment variables
export OTEL_SERVICE_NAME="langchain-anthropic-auto"
export OTEL_SERVICE_VERSION="1.0.0"
export OTEL_DEPLOYMENT_ENVIRONMENT="local"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
export OTEL_EXPORTER_OTLP_INSECURE="true"

# Load .env file from repository root (two levels up)
if [ -f ../../.env ]; then
    set -a
    source ../../.env
    set +a
fi

# Run with auto-instrumentation
opentelemetry-instrument python app.py
