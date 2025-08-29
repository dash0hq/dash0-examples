#!/bin/bash

# Todo Load Generation Script
# Creates and deletes todos continuously at a reasonable pace for observability testing

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_URL="${FRONTEND_URL:-http://localhost:31000}"
CREATE_INTERVAL="${CREATE_INTERVAL:-5}"  # seconds between creates
DELETE_INTERVAL="${DELETE_INTERVAL:-8}"  # seconds between deletes
MAX_TODOS="${MAX_TODOS:-10}"             # maximum todos to keep active
VARIATION="${VARIATION:-true}"           # add some timing variation

echo -e "${GREEN}🔄 Starting Todo Load Generation${NC}"
echo "=================================="
echo "Frontend URL: $FRONTEND_URL"
echo "Create interval: ${CREATE_INTERVAL}s"
echo "Delete interval: ${DELETE_INTERVAL}s" 
echo "Max active todos: $MAX_TODOS"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Arrays of realistic todo items for variety
TODO_TITLES=(
    "Buy groceries"
    "Review pull request"
    "Schedule team meeting"
    "Update documentation"
    "Fix authentication bug"
    "Plan sprint retrospective"
    "Test new feature"
    "Refactor user service"
    "Deploy to staging"
    "Monitor performance metrics"
    "Backup database"
    "Update dependencies"
    "Write unit tests"
    "Review security audit"
    "Optimize database queries"
    "Setup CI/CD pipeline"
    "Create API documentation" 
    "Implement feature flags"
    "Configure logging"
    "Setup monitoring alerts"
)

TODO_DESCRIPTIONS=(
    "High priority task"
    "Quick fix needed"
    "Requires testing"
    "Blocked on external dependency"
    "Ready for review"
    "In progress"
    "Needs investigation"
    "Low priority maintenance"
    "Enhancement request"
    "Technical debt cleanup"
)

# Function to get random element from array
get_random_element() {
    local arr=("$@")
    local len=${#arr[@]}
    local idx=$((RANDOM % len))
    echo "${arr[$idx]}"
}

# Function to get variation in timing (±2 seconds)
get_sleep_time() {
    local base_time=$1
    if [ "$VARIATION" = "true" ]; then
        local variation=$((RANDOM % 5 - 2))  # -2 to +2 seconds
        local sleep_time=$((base_time + variation))
        echo $((sleep_time > 1 ? sleep_time : 1))  # minimum 1 second
    else
        echo $base_time
    fi
}

# Function to create a todo
create_todo() {
    local title=$(get_random_element "${TODO_TITLES[@]}")
    local description=$(get_random_element "${TODO_DESCRIPTIONS[@]}")
    
    echo -e "${BLUE}Creating:${NC} $title"
    
    # Create todo via frontend API with browser-like headers
    local response=$(curl -s -X POST "$FRONTEND_URL/v1.0/invoke/todo-service/method/todos" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "User-Agent: LoadGenerator/1.0" \
        -H "Origin: http://localhost:31000" \
        -d "{\"name\": \"$title\"}" \
        -w "%{http_code}" -o /tmp/create_response.json 2>/dev/null)
    
    if [ "$response" -eq 201 ] || [ "$response" -eq 200 ]; then
        local todo_id=$(jq -r '.id // empty' /tmp/create_response.json 2>/dev/null)
        if [ -n "$todo_id" ]; then
            echo "  ✓ Created todo ID: $todo_id"
            echo "$todo_id" >> /tmp/todo_ids.txt
        else
            echo "  ✓ Todo created (no ID returned)"
        fi
    else
        echo -e "  ${RED}✗ Failed to create todo (HTTP: $response)${NC}"
    fi
}

# Function to delete a random todo
delete_todo() {
    if [ ! -f /tmp/todo_ids.txt ] || [ ! -s /tmp/todo_ids.txt ]; then
        echo -e "${YELLOW}No todos to delete${NC}"
        return
    fi
    
    # Get random todo ID from file
    local todo_id=$(shuf -n 1 /tmp/todo_ids.txt)
    if [ -z "$todo_id" ]; then
        return
    fi
    
    echo -e "${BLUE}Deleting:${NC} Todo ID $todo_id"
    
    # Delete todo via frontend API with browser-like headers
    local response=$(curl -s -X DELETE "$FRONTEND_URL/v1.0/invoke/todo-service/method/todos/$todo_id" \
        -H "Accept: application/json" \
        -H "User-Agent: LoadGenerator/1.0" \
        -H "Origin: http://localhost:31000" \
        -w "%{http_code}" -o /dev/null 2>/dev/null)
    
    if [ "$response" -eq 204 ] || [ "$response" -eq 200 ]; then
        echo "  ✓ Deleted todo ID: $todo_id"
        # Remove from tracking file
        grep -v "^$todo_id$" /tmp/todo_ids.txt > /tmp/todo_ids_temp.txt 2>/dev/null || true
        mv /tmp/todo_ids_temp.txt /tmp/todo_ids.txt 2>/dev/null || true
    else
        echo -e "  ${RED}✗ Failed to delete todo (HTTP: $response)${NC}"
    fi
}

# Function to get current todo count
get_todo_count() {
    if [ ! -f /tmp/todo_ids.txt ]; then
        echo 0
    else
        wc -l < /tmp/todo_ids.txt 2>/dev/null || echo 0
    fi
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    rm -f /tmp/todo_ids.txt /tmp/create_response.json /tmp/todo_ids_temp.txt
    echo "Load generation stopped"
    exit 0
}

# Trap Ctrl+C
trap cleanup INT

# Initialize tracking file
rm -f /tmp/todo_ids.txt
touch /tmp/todo_ids.txt

# Check if frontend is accessible
echo "Testing frontend connectivity..."
if ! curl -s --connect-timeout 5 "$FRONTEND_URL/health" >/dev/null 2>&1 && \
   ! curl -s --connect-timeout 5 "$FRONTEND_URL" >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to frontend at $FRONTEND_URL${NC}"
    echo "Make sure the frontend is running and accessible"
    echo "You can also set FRONTEND_URL environment variable"
    exit 1
fi
echo -e "${GREEN}✓ Frontend accessible${NC}"
echo ""

# Main load generation loop
create_counter=0
delete_counter=0

while true; do
    current_count=$(get_todo_count)
    
    # Create todos if under limit
    if [ "$current_count" -lt "$MAX_TODOS" ]; then
        create_todo
        create_counter=$((create_counter + 1))
        
        # Sleep before next action
        sleep_time=$(get_sleep_time $CREATE_INTERVAL)
        sleep $sleep_time
    fi
    
    # Delete todos periodically to keep count manageable
    if [ "$current_count" -gt 3 ]; then
        delete_todo
        delete_counter=$((delete_counter + 1))
        
        # Sleep before next action  
        sleep_time=$(get_sleep_time $DELETE_INTERVAL)
        sleep $sleep_time
    fi
    
    # Progress indicator every 10 operations
    total_ops=$((create_counter + delete_counter))
    if [ $((total_ops % 10)) -eq 0 ] && [ $total_ops -gt 0 ]; then
        echo -e "${GREEN}Stats: Created $create_counter, Deleted $delete_counter, Active: $(get_todo_count)${NC}"
    fi
done