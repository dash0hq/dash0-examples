#!/bin/bash

# Complete setup script for ingress-nginx demo with observability
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up ingress-nginx Demo with Observability${NC}"
echo "=================================================="
echo ""
echo "This will:"
echo "1. Create a Kind cluster with ingress support"
echo "2. Install local observability stack (Jaeger, Prometheus, OpenSearch)"
echo "3. Install OpenTelemetry stack"
echo "4. Install ingress-nginx with OpenTelemetry support"
echo "5. Deploy a demo Node.js application"
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
echo -e "${BLUE}1/5: Setting up Kind cluster...${NC}"
"${SCRIPT_DIR}/scripts/01_setup_cluster.sh"
echo ""

echo -e "${BLUE}2/5: Installing local observability stack...${NC}"
"${SCRIPT_DIR}/scripts/05_install_observability_stack.sh"
echo ""

echo -e "${BLUE}3/5: Installing OpenTelemetry stack...${NC}"
"${SCRIPT_DIR}/scripts/02_install_otel.sh"
echo ""

echo -e "${BLUE}4/5: Installing ingress-nginx...${NC}"
"${SCRIPT_DIR}/scripts/03_install_nginx.sh"
echo ""

echo -e "${BLUE}5/5: Deploying demo applications...${NC}"
"${SCRIPT_DIR}/scripts/04_deploy_apps.sh"
echo ""

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Add to /etc/hosts:"
echo "   sudo echo '127.0.0.1 nodejs.localhost' >> /etc/hosts"
echo ""
echo "2. Access the demo application:"
echo "   http://nodejs.localhost"
echo ""
echo "3. Generate load for testing:"
echo "   ./scripts/load-test.sh --duration 300 --rate 20"
echo ""
echo "4. View telemetry:"
echo ""
echo "   ${YELLOW}Dash0 (primary):${NC}"
echo "   - Metrics: ingress-nginx controller metrics"
echo "   - Traces: Distributed traces from ingress-nginx"
echo "   - Logs: Access logs with trace correlation"
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
echo -e "${BLUE}Cluster components:${NC}"
kubectl get pods -A