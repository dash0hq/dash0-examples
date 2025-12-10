#!/bin/bash

# Complete setup script for Linkerd demo with observability
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Linkerd Demo with Observability${NC}"
echo "============================================"
echo ""
echo "This will:"
echo "1. Create a Kind cluster"
echo "2. Install Linkerd with tracing enabled"
echo "3. Install OpenTelemetry Collectors (in the mesh)"
echo "4. Deploy the emojivoto demo application"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for environment file
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Environment file not found at ${ENV_FILE}${NC}"
    echo "Please copy .env.template to .env and configure it with your Dash0 credentials."
    exit 1
fi

echo -e "${BLUE}Executing setup scripts...${NC}"
echo ""

# Make scripts executable
chmod +x "${SCRIPT_DIR}/scripts"/*.sh

# Run setup scripts
echo -e "${BLUE}1/4: Setting up Kind cluster...${NC}"
"${SCRIPT_DIR}/scripts/01_setup_cluster.sh"
echo ""

echo -e "${BLUE}2/4: Installing Linkerd...${NC}"
"${SCRIPT_DIR}/scripts/02_install_linkerd.sh"
echo ""

echo -e "${BLUE}3/4: Installing OpenTelemetry stack...${NC}"
"${SCRIPT_DIR}/scripts/03_install_otel.sh"
echo ""

echo -e "${BLUE}4/4: Deploying emojivoto demo...${NC}"
"${SCRIPT_DIR}/scripts/04_deploy_emojivoto.sh"
echo ""

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Port forward to access emojivoto:"
echo "   kubectl port-forward -n emojivoto svc/web-svc 8080:80 &"
echo ""
echo "2. Open the emojivoto web UI:"
echo "   open http://localhost:8080"
echo ""
echo "3. Generate load for testing:"
echo "   ./scripts/load-test.sh --duration 300 --rate 20"
echo ""
echo "4. Access the Linkerd dashboard:"
echo "   linkerd viz install | kubectl apply -f -"
echo "   linkerd viz dashboard &"
echo ""
echo "5. Check your Dash0 dashboard for metrics, traces, and logs!"
echo ""
echo -e "${BLUE}Cluster components:${NC}"
kubectl get pods -A
