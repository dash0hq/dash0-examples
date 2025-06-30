#!/usr/bin/env bash

set -eo pipefail

# Source environment variables from .env file
if [ -f "../.env" ]; then
    source ../.env
else
    echo "Error: .env file not found. Please copy .env.template to .env and configure your settings."
    exit 1
fi

echo "Starting Java instrumentation example with Docker Compose..."
echo "Using OTEL Collector image: $OPENTELEMETRY_COLLECTOR_CONTAINER_IMAGE"

# Export environment variables for docker-compose
export DASH0_AUTH_TOKEN
export DASH0_DATASET
export DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME
export DASH0_ENDPOINT_OTLP_GRPC_PORT
export DASH0_ENDPOINT_OTLP_HTTP_HOSTNAME
export DASH0_ENDPOINT_OTLP_HTTP_PORT
export OPENTELEMETRY_COLLECTOR_CONTAINER_IMAGE
export OPENTELEMETRY_COLLECTOR_LOG_LEVEL

# Run docker-compose
docker-compose up --build