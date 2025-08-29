#!/bin/bash

# Load generation script for Traefik demo
# Generates traffic to test ingress and observability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DURATION=${DURATION:-60}
RATE=${RATE:-10}
CONCURRENT=${CONCURRENT:-5}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --rate)
            RATE="$2"
            shift 2
            ;;
        --concurrent)
            CONCURRENT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --duration SECONDS   Duration of the test in seconds (default: 60)"
            echo "  --rate RPS          Requests per second (default: 10)"
            echo "  --concurrent N      Number of concurrent connections (default: 5)"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🚀 Starting load test for Traefik demo${NC}"
echo "================================="
echo "Duration: ${DURATION}s"
echo "Rate: ${RATE} requests/second"
echo "Concurrent connections: ${CONCURRENT}"
echo ""

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

# Check if Traefik is running
if ! kubectl get pods -n traefik -l app.kubernetes.io/name=traefik 2>/dev/null | grep -q Running; then
    echo -e "${YELLOW}⚠️  Traefik doesn't appear to be running. Checking...${NC}"
    kubectl get pods -n traefik
fi

# Check if nodejs-app is running
if ! kubectl get pods -n demo -l app=nodejs-app 2>/dev/null | grep -q Running; then
    echo -e "${RED}❌ Node.js app is not running. Please deploy it first.${NC}"
    exit 1
fi

echo -e "${BLUE}Testing endpoints...${NC}"

# Test Traefik dashboard
echo -n "Testing Traefik dashboard (http://localhost:8080/dashboard/)... "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/dashboard/ | grep -q "200\|404"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}✗ (may not be exposed)${NC}"
fi

# Test nodejs app through ingress
echo -n "Testing Node.js app via ingress (http://nodejs.localhost)... "
if curl -s -o /dev/null -w "%{http_code}" -H "Host: nodejs.localhost" http://localhost | grep -q "200"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Note: You may need to add '127.0.0.1 nodejs.localhost' to /etc/hosts"
fi

echo ""
echo -e "${BLUE}Starting load generation...${NC}"

# Function to generate load
generate_load() {
    local endpoint=$1
    local host_header=$2
    local label=$3
    
    echo -e "${YELLOW}Generating load for ${label}...${NC}"
    
    # Using curl in a loop for simplicity
    for ((i=1; i<=DURATION; i++)); do
        for ((j=1; j<=RATE; j++)); do
            {
                if [ -n "$host_header" ]; then
                    curl -s -o /dev/null -H "Host: $host_header" "$endpoint" &
                else
                    curl -s -o /dev/null "$endpoint" &
                fi
            } 2>/dev/null
        done
        
        # Progress indicator
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "${BLUE}Progress: $i/$DURATION seconds${NC}"
        fi
        
        sleep 1
        
        # Limit concurrent connections
        while [ $(jobs -r | wc -l) -ge $((CONCURRENT * RATE)) ]; do
            sleep 0.1
        done
    done
    
    # Wait for remaining requests
    wait
}

# Generate different types of traffic
echo -e "${BLUE}Generating normal traffic to Node.js app...${NC}"
generate_load "http://localhost" "nodejs.localhost" "nodejs-app" &
PID1=$!

# Generate some 404 errors
echo -e "${BLUE}Generating 404 errors...${NC}"
for ((i=1; i<=10; i++)); do
    curl -s -o /dev/null -H "Host: nodejs.localhost" "http://localhost/nonexistent-$i" &
    sleep 2
done &
PID2=$!

# Skip PID3 since we removed the extra endpoints
PID3=""

# Wait for all background processes
wait $PID1 $PID2

echo ""
echo -e "${GREEN}✅ Load test completed!${NC}"
echo ""
echo "Check metrics in Dash0:"
echo "  - Traefik request rate and latency"
echo "  - Error rates (4xx, 5xx)"
echo "  - Service traces (Traefik → Node.js)"
echo ""
echo "View local Traefik dashboard:"
echo "  http://localhost:8080/dashboard/"