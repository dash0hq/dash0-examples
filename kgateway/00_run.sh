#!/bin/bash

# Main script to run the complete kgateway demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║           kgateway + OpenTelemetry + Dash0               ║"
echo "║                     Demo Setup                            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run all setup scripts in order
echo -e "${BLUE}Running complete demo setup...${NC}"
echo ""

"${SCRIPT_DIR}/scripts/01_setup_cluster.sh"
echo ""

"${SCRIPT_DIR}/scripts/05_build_nodejs_app.sh"
echo ""

"${SCRIPT_DIR}/scripts/06_install_observability_stack.sh"
echo ""

"${SCRIPT_DIR}/scripts/02_install_otel.sh"
echo ""

"${SCRIPT_DIR}/scripts/03_install_kgateway.sh"
echo ""

"${SCRIPT_DIR}/scripts/04_deploy_apps.sh"
echo ""

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              ✅ Demo Setup Complete! ✅                   ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Next steps:"
echo "  1. Access the gateway:"
echo "     kubectl port-forward -n kgateway-system svc/http 8080:80"
echo ""
echo "  2. Test the application:"
echo "     curl -H 'Host: node.dash0-examples.com' http://localhost:8080/"
echo ""
echo "  3. View telemetry:"
echo ""
echo "     ${YELLOW}Dash0 (primary):${NC}"
echo "     - Metrics: kgateway controller and proxy metrics"
echo "     - Traces: Distributed traces from kgateway"
echo "     - Logs: Access logs with trace correlation"
echo ""
echo "     ${YELLOW}Local Observability Stack:${NC}"
echo "       Jaeger:    kubectl port-forward -n default svc/jaeger-query 16686:16686"
echo "                  http://localhost:16686"
echo ""
echo "       Prometheus: kubectl port-forward -n default svc/prometheus 9090:9090"
echo "                   http://localhost:9090"
echo ""
echo "       OpenSearch: kubectl port-forward -n default svc/opensearch-dashboards 5601:5601"
echo "                   http://localhost:5601 (admin / SecureP@ssw0rd123)"
echo ""
echo "  4. Clean up when done:"
echo "     ./01_cleanup.sh"
echo ""
