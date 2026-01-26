#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Setting up Auto-Instrumentation Demo ==="
echo ""

cd "${PROJECT_ROOT}/auto"

# Clean up any existing venv
if [ -d ".venv" ]; then
    echo "Removing existing virtual environment..."
    rm -rf .venv
fi

echo "Creating virtual environment..."
uv venv

echo "Installing dependencies..."
uv pip install -r requirements.txt

echo "Bootstrapping OpenTelemetry auto-instrumentation..."
.venv/bin/opentelemetry-bootstrap -a install

echo ""
echo "✅ Auto-instrumentation demo setup complete!"
