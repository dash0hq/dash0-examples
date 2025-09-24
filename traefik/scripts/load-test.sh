#!/bin/bash

set -euo pipefail

# Simple load test parameters
DURATION=60
RATE=10
HOST="nodejs.localhost"
BASE_URL="http://localhost"

echo "🚀 Starting load test..."
echo "Duration: ${DURATION}s"
echo "Rate: ${RATE} requests/second"
echo "Target: ${HOST}"
echo

# Check if target is reachable
echo "🔍 Testing connectivity..."
if ! curl -s -H "Host: ${HOST}" "${BASE_URL}" > /dev/null; then
    echo "❌ Cannot reach ${HOST}. Is the application running?"
    echo "   Make sure you've added '127.0.0.1 ${HOST}' to /etc/hosts"
    exit 1
fi
echo "✅ Target is reachable"
echo

echo "📊 Generating traffic for ${DURATION} seconds at ${RATE} RPS..."

# Simple load generation
count=0
errors=0
start_time=$(date +%s)

for ((i=1; i<=DURATION*RATE; i++)); do
    response=$(curl -s -w "%{http_code}" -H "Host: ${HOST}" "${BASE_URL}" -o /dev/null 2>/dev/null || echo "000")

    if [[ $response == "200" ]]; then
        ((count++))
    else
        ((errors++))
    fi

    # Simple rate limiting - sleep for remaining time
    sleep 0.1
done

end_time=$(date +%s)
actual_duration=$((end_time - start_time))

echo
echo "✅ Load test completed!"
echo "📊 Results: $count successful, $errors errors in ${actual_duration}s"
echo
echo "📈 Check your Dash0 dashboard to see:"
echo "  • Request rates and response times"
echo "  • Error rates and status code distribution"
echo "  • Distributed traces showing request flow"
echo "  • OTLP logs with trace correlation"
echo