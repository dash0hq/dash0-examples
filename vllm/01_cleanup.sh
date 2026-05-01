#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}=== vLLM Demo Cleanup ===${NC}"
echo ""

cd "$SCRIPT_DIR"

if docker compose version &>/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "Docker Compose not found — nothing to clean up."
    exit 0
fi

read -p "Also remove the cached model weights (~500 MB)? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    $COMPOSE_CMD down -v
    echo -e "${GREEN}✓ Containers stopped and volumes removed.${NC}"
else
    $COMPOSE_CMD down
    echo -e "${GREEN}✓ Containers stopped. Model weights kept in Docker volume 'huggingface-cache'.${NC}"
fi
