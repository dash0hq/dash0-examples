#!/bin/bash

# Test various OpenTelemetry features of Istio
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Testing Istio OpenTelemetry Features${NC}"
echo "========================================"

# Set up port-forward to ingress gateway
echo -e "${BLUE}Setting up port-forward to istio-ingressgateway...${NC}"
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait for port-forward to be ready
sleep 2

# Cleanup function
cleanup() {
    echo -e "${BLUE}Cleaning up port-forward...${NC}"
    kill $PORT_FORWARD_PID 2>/dev/null || true
}
trap cleanup EXIT

export INGRESS_HOST="localhost"
export INGRESS_PORT="8080"

echo -e "${BLUE}Ingress Gateway: http://$INGRESS_HOST:$INGRESS_PORT${NC}"
echo ""

echo -e "${BLUE}Test 1: Basic Request (Trace Generation)${NC}"
echo "==========================================="
curl -s -H "Host: service-a.dash0-examples.com" \
     http://$INGRESS_HOST:$INGRESS_PORT/ | jq .
echo -e "${GREEN}✓ Request completed${NC}"
echo ""

echo -e "${BLUE}Test 2: W3C TraceContext Propagation${NC}"
echo "========================================"
TRACE_ID="4bf92f3577b34da6a3ce929d0e0e4736"
SPAN_ID="00f067aa0ba902b7"
curl -s -H "Host: service-a.dash0-examples.com" \
     -H "traceparent: 00-${TRACE_ID}-${SPAN_ID}-01" \
     http://$INGRESS_HOST:$INGRESS_PORT/ | jq .
echo -e "${GREEN}✓ Check Jaeger for trace ID: $TRACE_ID${NC}"
echo ""

echo -e "${BLUE}Test 3: B3 Propagation (Zipkin format)${NC}"
echo "========================================"
TRACE_ID="5cf92f3577b34da6a3ce929d0e0e4737"
SPAN_ID="10f067aa0ba902b8"
curl -s -H "Host: service-a.dash0-examples.com" \
     -H "X-B3-TraceId: ${TRACE_ID}" \
     -H "X-B3-SpanId: ${SPAN_ID}" \
     -H "X-B3-Sampled: 1" \
     http://$INGRESS_HOST:$INGRESS_PORT/ | jq .
echo -e "${GREEN}✓ Check Jaeger for trace ID: $TRACE_ID${NC}"
echo ""

echo -e "${BLUE}Test 4: Service Mesh Communication (Frontend → Backend)${NC}"
echo "========================================================"
echo "  Testing /api/backend endpoint (calls backend service)"
curl -s -H "Host: service-a.dash0-examples.com" \
     http://$INGRESS_HOST:$INGRESS_PORT/api/backend | jq .
echo -e "${GREEN}✓ Check traces for service mesh communication (should show multi-service trace)${NC}"
echo ""

echo -e "${BLUE}Test 5: Data Processing Through Mesh${NC}"
echo "======================================"
echo "  Testing /api/process endpoint (POST to backend)"
curl -s -H "Host: service-a.dash0-examples.com" \
     -H "Content-Type: application/json" \
     -d '{"test":"data","value":123}' \
     http://$INGRESS_HOST:$INGRESS_PORT/api/process | jq .
echo -e "${GREEN}✓ Check traces for POST request through mesh${NC}"
echo ""

echo -e "${BLUE}Test 6: Error Propagation Through Mesh${NC}"
echo "========================================"
echo "  Testing /api/error endpoint (triggers backend error)"
curl -s -H "Host: service-a.dash0-examples.com" \
     http://$INGRESS_HOST:$INGRESS_PORT/api/error || true
echo -e "${GREEN}✓ Check traces for error propagation (both services should show error spans)${NC}"
echo ""

echo -e "${BLUE}Test 7: Load Generation (Metrics & Mesh Traffic)${NC}"
echo "================================================="
echo "Generating 50 requests (mix of frontend and mesh calls)..."
for i in {1..50}; do
    if [ $((i % 3)) -eq 0 ]; then
        curl -s -H "Host: service-a.dash0-examples.com" \
             http://$INGRESS_HOST:$INGRESS_PORT/api/backend > /dev/null &
    else
        curl -s -H "Host: service-a.dash0-examples.com" \
             http://$INGRESS_HOST:$INGRESS_PORT/ > /dev/null &
    fi
done
wait
echo -e "${GREEN}✓ Check Prometheus for istio_requests_total and envoy_cluster_upstream_rq_total${NC}"
echo -e "${GREEN}✓ Check service graph in Dash0/Jaeger for frontend → backend connections${NC}"
echo ""

echo -e "${BLUE}Test 8: Slow Request Through Mesh (Latency Traces)${NC}"
echo "===================================================="
curl -s -H "Host: service-a.dash0-examples.com" \
     "http://$INGRESS_HOST:$INGRESS_PORT/api/slow" > /dev/null
echo -e "${GREEN}✓ Check trace for slow request through mesh (should show latency in both services)${NC}"
echo ""

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              ✅ All Tests Complete! ✅                   ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "View telemetry:"
echo "  ${YELLOW}Jaeger:${NC}"
echo "    kubectl port-forward -n default svc/jaeger-query 16686:16686"
echo "    http://localhost:16686"
echo ""
echo "  ${YELLOW}Prometheus:${NC}"
echo "    kubectl port-forward -n default svc/prometheus 9090:9090"
echo "    http://localhost:9090"
echo ""
echo "  ${YELLOW}OpenSearch Dashboards:${NC}"
echo "    kubectl port-forward -n default svc/opensearch-dashboards 5601:5601"
echo "    http://localhost:5601"
echo ""
echo "  ${YELLOW}Istio Access Logs:${NC}"
echo "    kubectl logs -n istio-system -l app=istio-ingressgateway -c istio-proxy --tail=20"
echo ""
