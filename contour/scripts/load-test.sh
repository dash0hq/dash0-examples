#!/bin/bash

# Simple load generation script for Contour demo
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting load test for Contour demo${NC}"
echo "================================="

# Check if port-forward is running
echo -n "Testing connection... "
if curl -s -o /dev/null -w "%{http_code}" -H "Host: node.dash0-examples.com" http://localhost:8080/ | grep -q "200"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Please run: kubectl port-forward -n projectcontour svc/envoy-contour 8080:80 &"
    exit 1
fi

echo -e "${BLUE}Generating traffic for 60 seconds...${NC}"

# Generate steady traffic
for i in {1..60}; do
    # Normal requests
    for j in {1..5}; do
        curl -s -o /dev/null -H "Host: node.dash0-examples.com" http://localhost:8080/ &
    done

    # Some 404s every 10 seconds
    if [ $((i % 10)) -eq 0 ]; then
        curl -s -o /dev/null -H "Host: node.dash0-examples.com" http://localhost:8080/notfound &
    fi

    # Progress
    if [ $((i % 15)) -eq 0 ]; then
        echo -e "${BLUE}Progress: $i/60 seconds${NC}"
    fi

    sleep 1
done

# Wait for background requests
wait

echo -e "${GREEN}✅ Load test completed!${NC}"