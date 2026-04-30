#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== vLLM + OpenTelemetry Demo Setup ===${NC}"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo -e "${RED}❌ docker is not installed${NC}"
    echo "Install from: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ docker found${NC}"

# Check Docker Compose (plugin or standalone)
if docker compose version &>/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}❌ Docker Compose not found${NC}"
    echo "Install from: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose found (${COMPOSE_CMD})${NC}"

# Check NVIDIA GPU
if ! command -v nvidia-smi &>/dev/null; then
    echo -e "${RED}❌ nvidia-smi not found — this demo requires an NVIDIA GPU${NC}"
    echo "  For testing without local hardware, a g4dn.xlarge EC2 instance (~\$0.50/hr) works well."
    exit 1
fi
if ! nvidia-smi --query-gpu=name --format=csv,noheader &>/dev/null; then
    echo -e "${RED}❌ NVIDIA driver not responding. Check your GPU drivers.${NC}"
    exit 1
fi
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
echo -e "${GREEN}✓ NVIDIA GPU detected: ${GPU_NAME}${NC}"

# Check .env file
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo -e "${RED}❌ .env file not found at ${ENV_FILE}${NC}"
    echo ""
    echo "Create it with the following content:"
    echo ""
    echo "  DASH0_AUTH_TOKEN=your_auth_token_here"
    echo "  DASH0_DATASET=default"
    echo "  DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=ingress.eu-west-1.aws.dash0.com"
    echo "  DASH0_ENDPOINT_OTLP_GRPC_PORT=4317"
    echo ""
    echo "Get your auth token from https://app.dash0.com/settings"
    exit 1
fi

# Validate required variables
set -a
source "$ENV_FILE"
set +a

missing=0
for var in DASH0_AUTH_TOKEN DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME DASH0_ENDPOINT_OTLP_GRPC_PORT; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ ${var} is not set in ${ENV_FILE}${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ ${var} is set${NC}"
    fi
done
if [ "$missing" -eq 1 ]; then exit 1; fi

echo ""
echo -e "${BLUE}Starting the stack...${NC}"
cd "$SCRIPT_DIR"
$COMPOSE_CMD up --build -d

echo ""
echo -e "${GREEN}Stack is starting.${NC}"
echo ""
echo "vLLM takes 2–5 minutes to load the model on first run. Follow the logs:"
echo ""
echo "  $COMPOSE_CMD logs -f vllm"
echo ""
echo "When you see 'Application startup complete.', the server is ready."
echo ""
echo "Send test requests:"
echo ""
echo "  python scripts/send-request.py"
echo ""
echo "Then check Dash0 for:"
echo "  Traces  — filter by service.name = rag-app or vllm-server"
echo "  Metrics — search for vllm:* or rag_queries_total"
echo ""
echo "To stop: ./01_cleanup.sh"
