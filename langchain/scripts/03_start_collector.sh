#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Starting OpenTelemetry Collector ==="
echo ""

cd "${PROJECT_ROOT}"

# Check if .env exists
if [ ! -f "../.env" ]; then
    echo "❌ Error: .env file not found in repository root"
    echo "Please create .env from .env.template and add your credentials"
    exit 1
fi

# Load environment variables for docker-compose to use
set -a
source "../.env"
set +a

echo "Starting collector with Docker Compose..."
docker-compose up -d

echo ""
echo "✅ Collector started!"
echo "  - Collector receiving on ports:"
echo "    - 4317 (gRPC)"
echo "    - 4318 (HTTP)"
echo ""
