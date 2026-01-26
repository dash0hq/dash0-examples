#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== LangChain OpenTelemetry Demo Setup ==="

# Check for uv
if ! command -v uv &> /dev/null; then
    echo "❌ Error: uv is not installed"
    echo "Install from: https://docs.astral.sh/uv/"
    exit 1
fi

# Check for docker
if ! command -v docker &> /dev/null; then
    echo "❌ Error: docker is not installed"
    exit 1
fi

# Setup manual demo
"${SCRIPT_DIR}/scripts/01_setup_manual.sh"

# Setup auto demo
"${SCRIPT_DIR}/scripts/02_setup_auto.sh"

# Start collector
"${SCRIPT_DIR}/scripts/03_start_collector.sh"

echo "=== Setup Complete! ==="
echo ""
echo "To run the demos:"
echo "  Manual:  cd ${SCRIPT_DIR}/manual && ./run.sh"
echo "  Auto:    cd ${SCRIPT_DIR}/auto && ./run.sh"