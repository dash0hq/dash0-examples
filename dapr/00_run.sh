#!/bin/bash

# Dapr Todo Demo - Main Deployment Script
# This script orchestrates the complete deployment using modular subscripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}🚀 Dapr Todo Demo - Complete Setup${NC}"
echo "======================================="
echo ""
echo "This script will:"
echo "  1. Setup Kind cluster with local registry"
echo "  2. Install Dapr"
echo "  3. Build all service images"
echo "  4. Deploy infrastructure (PostgreSQL, RabbitMQ cluster)"
echo "  5. Install OpenTelemetry (cert-manager, operator, collectors, instrumentation)"
echo "  6. Deploy Dapr components"
echo "  7. Deploy all services"
echo ""
echo -e "${YELLOW}Note: You can also run each step individually using scripts in the scripts/ directory${NC}"
echo ""
echo -n "Continue with full deployment? (y/n): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    echo ""
    echo "You can run individual steps:"
    echo "  ./scripts/01_setup_kind.sh              - Setup Kind cluster"
    echo "  ./scripts/02_install_dapr.sh            - Install Dapr"
    echo "  ./scripts/04_build_images.sh            - Build service images"
    echo "  ./scripts/05_deploy_infrastructure.sh   - Deploy infrastructure"
    echo "  ./scripts/03_install_otel.sh            - Install OpenTelemetry stack"
    echo "  ./scripts/06_deploy_dapr_components.sh  - Deploy Dapr components"
    echo "  ./scripts/07_deploy_services.sh         - Deploy services"
    exit 0
fi

# Make all scripts executable
chmod +x ${SCRIPT_DIR}/scripts/*.sh

# Step 1: Setup Kind cluster
echo -e "\n${BLUE}Step 1/7: Setting up Kind cluster...${NC}"
${SCRIPT_DIR}/scripts/01_setup_kind.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to setup Kind cluster${NC}"
    exit 1
fi

# Step 2: Install Dapr
echo -e "\n${BLUE}Step 2/7: Installing Dapr...${NC}"
${SCRIPT_DIR}/scripts/02_install_dapr.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install Dapr${NC}"
    exit 1
fi

# Step 3: Build images
echo -e "\n${BLUE}Step 3/7: Building service images...${NC}"
TAG=v1 ${SCRIPT_DIR}/scripts/04_build_images.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build images${NC}"
    exit 1
fi

# Step 4: Deploy infrastructure
echo -e "\n${BLUE}Step 4/7: Deploying infrastructure...${NC}"
${SCRIPT_DIR}/scripts/05_deploy_infrastructure.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy infrastructure${NC}"
    exit 1
fi

# Step 5: Install OpenTelemetry
echo -e "\n${BLUE}Step 5/7: Installing OpenTelemetry stack...${NC}"
${SCRIPT_DIR}/scripts/03_install_otel.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install OpenTelemetry${NC}"
    exit 1
fi

# Step 6: Deploy Dapr components
echo -e "\n${BLUE}Step 6/7: Deploying Dapr components...${NC}"
${SCRIPT_DIR}/scripts/06_deploy_dapr_components.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy Dapr components${NC}"
    exit 1
fi

# Step 7: Deploy services
echo -e "\n${BLUE}Step 7/7: Deploying services...${NC}"
${SCRIPT_DIR}/scripts/07_deploy_services.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy services${NC}"
    exit 1
fi

# Final summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📌 Access Points:${NC}"
echo "  Frontend:            http://localhost:31000"
echo "  RabbitMQ Management: http://localhost:31672 (guest/guest)"
echo ""
echo -e "${YELLOW}📊 Monitoring:${NC}"
echo "  Dapr Dashboard:      kubectl port-forward svc/dapr-dashboard 8080:8080 -n dapr-system"
echo "  View all pods:       kubectl get pods -n dapr-demo"
echo ""
echo -e "${YELLOW}🧹 Cleanup:${NC}"
echo "  Remove everything:   ./01_cleanup.sh"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"