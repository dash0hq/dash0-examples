#!/bin/bash

# Complete setup script for Contour demo with observability
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Contour Demo with Observability${NC}"
echo "============================================="
echo ""
echo "This will:"
echo "1. Create a Kind cluster with ingress support"
echo "2. Install OpenTelemetry stack"
echo "3. Install Contour with OpenTelemetry support"
echo "4. Deploy a demo Node.js application"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for environment file
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Environment file not found at ${ENV_FILE}${NC}"
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

echo -e "${BLUE}2/4: Installing OpenTelemetry stack...${NC}"
"${SCRIPT_DIR}/scripts/02_install_otel.sh"
echo ""

echo -e "${BLUE}3/4: Installing Contour...${NC}"
"${SCRIPT_DIR}/scripts/03_install_contour.sh"
echo ""

echo -e "${BLUE}4/4: Deploying demo applications...${NC}"
"${SCRIPT_DIR}/scripts/04_deploy_apps.sh"
echo ""

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Port forward to access the application:"
echo "   kubectl port-forward -n projectcontour svc/envoy-contour 8080:80 &"
echo ""
echo "2. Test the demo application:"
echo "   curl -H \"Host: node.dash0-examples.com\" http://localhost:8080"
echo ""
echo "3. Generate load for testing:"
echo "   ./scripts/load-test.sh --duration 300 --rate 20"
echo ""
echo "4. Check your Dash0 dashboard for metrics, traces, and logs!"
echo ""
echo -e "${BLUE}Cluster components:${NC}"
kubectl get pods -A