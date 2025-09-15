#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_URL="http://localhost:30000"
PRODUCER_URL="http://localhost:30001"

echo -e "${GREEN}KEDA Scaling Demo${NC}"
echo "=================="
echo ""
echo "1) HTTP load (6 req/s for 2 min)"
echo "2) RabbitMQ burst (600 messages)"
echo ""
echo -n "Choice (1-2): "
read -r choice

case $choice in
    1)
        echo -e "\n${BLUE}Starting HTTP load generation...${NC}"
        echo "Generating 6 requests/second for 2 minutes"
        
        for i in {1..120}; do
            for j in {1..6}; do
                curl -s "${APP_URL}/" > /dev/null 2>&1 &
            done
            sleep 1
            if [ $((i % 20)) -eq 0 ]; then
                echo "Progress: ${i}/120 seconds"
            fi
        done
        
        echo -e "${GREEN}✅ HTTP load complete${NC}"
        ;;
        
    2)
        echo -e "\n${BLUE}Sending RabbitMQ message burst...${NC}"
        echo "Pods before: $(kubectl get pods -n keda-demo -l app=rabbitmq-consumer --no-headers 2>/dev/null | wc -l)"
        
        curl -s -X POST "$PRODUCER_URL/burst" \
            -H "Content-Type: application/json" \
            -d '{"count": 600}' > /dev/null
            
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Sent 600 messages${NC}"
            echo "Watch scaling: kubectl get pods -n keda-demo -l app=rabbitmq-consumer -w"
        else
            echo -e "${YELLOW}⚠️ Failed to send messages${NC}"
        fi
        ;;
        
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Monitor: kubectl get pods -n keda-demo -w"