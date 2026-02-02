#!/bin/bash

# Traefik Demo - Main Deployment Script
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

echo -e "${GREEN}🚀 Traefik Demo - Complete Setup${NC}"
echo "======================================="
echo ""
echo "This script will:"
echo "  1. Setup Kind cluster with ingress support"
echo "  2. Install local observability stack (Jaeger, Prometheus, OpenSearch)"
echo "  3. Install OpenTelemetry Collectors (DaemonSet + Deployment)"
echo "  4. Install Traefik with OTLP observability"
echo "  5. Deploy Node.js demo application with auto-instrumentation"
echo ""
echo -e "${YELLOW}Note: You can also run each step individually using scripts in the scripts/ directory${NC}"
echo ""
echo -n "Continue with full deployment? (y/n): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    echo ""
    echo "You can run individual steps:"
    echo "  ./scripts/01_setup_cluster.sh    - Setup Kind cluster"
    echo "  ./scripts/02_install_otel.sh     - Install OpenTelemetry stack"
    echo "  ./scripts/03_install_traefik.sh  - Install Traefik"
    echo "  ./scripts/04_deploy_apps.sh      - Deploy test applications"
    echo "  ./scripts/load-test.sh           - Run load test"
    exit 0
fi

# Make all scripts executable
chmod +x ${SCRIPT_DIR}/scripts/*.sh

echo ""
echo -e "${BLUE}Starting deployment...${NC}"
echo "======================================="

# Step 1: Setup Kind cluster
echo ""
echo -e "${YELLOW}Step 1/5: Setting up Kind cluster${NC}"
echo "--------------------------------------"
"${SCRIPT_DIR}/scripts/01_setup_cluster.sh"

# Step 2: Install local observability stack
echo ""
echo -e "${YELLOW}Step 2/5: Installing local observability stack${NC}"
echo "--------------------------------------"
"${SCRIPT_DIR}/scripts/05_install_observability_stack.sh"

# Step 3: Install OpenTelemetry
echo ""
echo -e "${YELLOW}Step 3/5: Installing OpenTelemetry${NC}"
echo "--------------------------------------"
"${SCRIPT_DIR}/scripts/02_install_otel.sh"

# Step 4: Install Traefik
echo ""
echo -e "${YELLOW}Step 4/5: Installing Traefik${NC}"
echo "--------------------------------------"
"${SCRIPT_DIR}/scripts/03_install_traefik.sh"

# Step 5: Deploy applications
echo ""
echo -e "${YELLOW}Step 5/5: Deploying test applications${NC}"
echo "--------------------------------------"
"${SCRIPT_DIR}/scripts/04_deploy_apps.sh"

echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo "======================================="
echo ""
echo -e "${YELLOW}📝 Quick Start Guide:${NC}"
echo ""
echo "1. Add to /etc/hosts:"
echo "   sudo echo '127.0.0.1 nodejs.localhost' >> /etc/hosts"
echo ""
echo "2. Access services:"
echo "   - Node.js App: http://nodejs.localhost"
echo "   - Traefik Dashboard: http://localhost:8080/dashboard/"
echo ""
echo "3. Generate load:"
echo "   ./scripts/load-test.sh"
echo ""
echo "4. View telemetry:"
echo ""
echo "   ${YELLOW}Dash0 (primary):${NC}"
echo "   - Check your Dash0 dashboard for Traefik metrics"
echo "   - Look for service.namespace=traefik-demo"
echo "   - Monitor HTTP request metrics, traces, and logs"
echo ""
echo "   ${YELLOW}Local Observability Stack:${NC}"
echo "     Jaeger:    kubectl port-forward -n default svc/jaeger-query 16686:16686"
echo "                http://localhost:16686"
echo ""
echo "     Prometheus: kubectl port-forward -n default svc/prometheus 9090:9090"
echo "                 http://localhost:9090"
echo ""
echo "     OpenSearch: kubectl port-forward -n default svc/opensearch-dashboards 5601:5601"
echo "                 http://localhost:5601 (admin / SecureP@ssw0rd123)"
echo ""
echo "5. Clean up:"
echo "   ./01_cleanup.sh"