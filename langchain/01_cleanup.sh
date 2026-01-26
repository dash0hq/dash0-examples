#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Cleaning up LangChain Demo ==="
echo ""

# Stop Docker containers
echo "Stopping Docker containers..."
cd "${SCRIPT_DIR}"
docker-compose down 2>/dev/null || true

# Remove virtual environments
echo "Removing virtual environments..."
rm -rf "${SCRIPT_DIR}/manual/.venv"
rm -rf "${SCRIPT_DIR}/auto/.venv"

echo ""
echo "✅ Cleanup complete!"
