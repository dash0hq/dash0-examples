#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_URL="http://localhost:30000"

echo -e "${GREEN}Load Generator${NC}"
echo "=============="
echo ""
echo "1) HTTP requests (trigger at >1 req/s)"
echo "2) Queue items (trigger at >30 items)"
echo "3) Both HTTP + Queue load"
echo ""
echo -n "Choice (1-3): "
read -r choice

case $choice in
    1)
        echo -e "\n${BLUE}Generating sustained HTTP load...${NC}"
        echo "Sending 6 requests/second for 2 minutes"
        echo -e "${YELLOW}This should trigger scaling, then scale back down${NC}"
        echo ""
        
        # Background process to generate consistent load
        (
            for i in {1..120}; do  # 2 minutes
                for j in {1..6}; do  # 6 requests per second
                    curl -s "${APP_URL}/" > /dev/null 2>&1 &
                done
                sleep 1
                if [ $((i % 10)) -eq 0 ]; then
                    echo "$(date): ${i}/120 seconds - Generated $((i * 6)) total requests"
                fi
            done
            echo -e "\n${GREEN}Load generation completed!${NC}"
        ) &
        
        LOAD_PID=$!
        echo "Load generation started (PID: $LOAD_PID)"
        echo "Press Ctrl+C to stop early, or wait 2 minutes"
        
        # Allow user to stop early
        trap "kill $LOAD_PID 2>/dev/null; echo -e '\n${YELLOW}Load generation stopped${NC}'; exit 0" INT
        wait $LOAD_PID
        ;;
        
    2)
        echo -e "\n${BLUE}Adding items to queue...${NC}"
        curl -X POST "${APP_URL}/simulate-load" \
            -H "Content-Type: application/json" \
            -d '{"items": 100}' | jq .
        echo -e "${GREEN}Queue will process in 30 seconds${NC}"
        ;;
        
    3)
        echo -e "\n${BLUE}Generating combined load...${NC}"
        
        # Start HTTP load in background
        (
            for i in {1..120}; do  # 2 minutes
                for j in {1..4}; do
                    curl -s "${APP_URL}/" > /dev/null 2>&1 &
                done
                sleep 1
            done
        ) &
        
        # Add queue load
        curl -X POST "${APP_URL}/simulate-load" \
            -H "Content-Type: application/json" \
            -d '{"items": 80}' > /dev/null 2>&1
            
        echo "Combined load started:"
        echo "- HTTP: 4 req/s for 2 minutes"
        echo "- Queue: 80 items (30s processing)"
        echo -e "${YELLOW}Should trigger scaling on both metrics${NC}"
        ;;
        
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Monitor scaling:"
echo "  kubectl get hpa -n keda-demo -w"
echo "  kubectl get pods -n keda-demo -w"