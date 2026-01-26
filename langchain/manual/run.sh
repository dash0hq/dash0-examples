#!/bin/bash
# Run the manually instrumented demo

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate virtual environment
source "${SCRIPT_DIR}/.venv/bin/activate"

# Load .env file from repository root (two levels up)
if [ -f ../../.env ]; then
    set -a
    source ../../.env
    set +a
fi

# Run the app directly (telemetry is configured in code)
python app.py
