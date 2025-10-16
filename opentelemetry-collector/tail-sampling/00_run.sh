#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Use provided config file or default to config.yaml
CONFIG_FILE="${1:-config.yaml}"

# Validate that the config file exists
if [ ! -f "$(pwd)/$CONFIG_FILE" ]; then
  echo "Error: Config file '$CONFIG_FILE' not found in $(pwd)"
  exit 1
fi

echo "Starting OpenTelemetry Collector with $CONFIG_FILE"
echo ""

docker run \
  --rm \
  --publish 4317:4317 \
  --publish 4318:4318 \
  -v "$(pwd)/$CONFIG_FILE:/etc/otelcol-contrib/config.yaml" \
  -e "DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=$DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME" \
  -e "DASH0_ENDPOINT_OTLP_GRPC_PORT=$DASH0_ENDPOINT_OTLP_GRPC_PORT" \
  -e "DASH0_AUTH_TOKEN=$DASH0_AUTH_TOKEN" \
  -e "DASH0_DATASET=$DASH0_DATASET" \
  -e "OPENTELEMETRY_COLLECTOR_LOG_LEVEL=$OPENTELEMETRY_COLLECTOR_LOG_LEVEL" \
  $OPENTELEMETRY_COLLECTOR_CONTAINER_IMAGE
