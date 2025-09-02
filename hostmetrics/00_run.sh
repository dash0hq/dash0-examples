#!/bin/bash

# Hostmetrics Demo - Main Deployment Script
# This script sets up a Kind cluster and deploys OpenTelemetry Collector with hostmetrics receiver

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}🚀 Hostmetrics Demo - Setup${NC}"
echo "======================================="
echo ""
echo "This script will:"
echo "  1. Setup Kind cluster (2 nodes)"
echo "  2. Install OpenTelemetry Collector with hostmetrics receiver"
echo "  3. Configure export to Dash0"
echo ""
echo -e "${YELLOW}Note: You can also run each step individually using scripts in the scripts/ directory${NC}"
echo ""
echo -n "Continue with deployment? (y/n): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    echo ""
    echo "You can run individual steps:"
    echo "  ./scripts/01_setup_kind.sh     - Setup Kind cluster"
    echo "  ./scripts/02_install_otel.sh   - Install OpenTelemetry Collector"
    exit 0
fi

# Make all scripts executable
chmod +x ${SCRIPT_DIR}/scripts/*.sh

# Step 1: Setup Kind cluster
echo -e "\n${BLUE}Step 1/2: Setting up Kind cluster...${NC}"
${SCRIPT_DIR}/scripts/01_setup_kind.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to setup Kind cluster${NC}"
    exit 1
fi

# Step 2: Install OpenTelemetry Collector
echo -e "\n${BLUE}Step 2/2: Installing OpenTelemetry Collector...${NC}"
${SCRIPT_DIR}/scripts/02_install_otel.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install OpenTelemetry Collector${NC}"
    exit 1
fi

# Final summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📊 Monitoring:${NC}"
echo "  The OpenTelemetry Collector is now collecting host metrics from both nodes"
echo "  Metrics are being exported to Dash0"
echo ""
echo "  View collector pods:"
echo "    kubectl get pods -n opentelemetry"
echo ""
echo "  View collector logs:"
echo "    kubectl logs -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector --tail=50 -f"
echo ""
echo -e "${YELLOW}🧹 Cleanup:${NC}"
echo "  Remove everything:   ./01_cleanup.sh"
echo ""
echo -e "${GREEN}Happy monitoring! 🚀${NC}"