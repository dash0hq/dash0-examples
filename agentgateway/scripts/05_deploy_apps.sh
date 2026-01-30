#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$PROJECT_DIR")"

echo "Deploying agentgateway Anthropic backend..."

# Load environment variables
if [ -f "$ROOT_DIR/.env" ]; then
  export $(cat "$ROOT_DIR/.env" | grep -v '^#' | xargs)
else
  echo "Warning: $ROOT_DIR/.env file not found"
  echo "ANTHROPIC_API_KEY is required for this demo"
  exit 1
fi

# Create Anthropic API key secret in agentgateway-system namespace
if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "Creating Anthropic API key secret..."
  kubectl create secret generic anthropic-secret \
    --from-literal=Authorization="$ANTHROPIC_API_KEY" \
    -n agentgateway-system \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "Error: ANTHROPIC_API_KEY not found in .env"
  exit 1
fi

# Deploy AgentgatewayBackend and HTTPRoute for Anthropic
echo "Deploying AgentgatewayBackend for Anthropic..."
kubectl apply -f "$PROJECT_DIR/agentgateway/anthropic-backend.yaml"

# Apply prompt guard policy
echo "Applying prompt guard policy..."
kubectl apply -f "$PROJECT_DIR/agentgateway/prompt-guard-policy.yaml"

echo ""
echo "============================================"
echo "Agentgateway Anthropic backend deployed!"
echo "============================================"
echo ""
echo "Access the gateway:"
echo "  kubectl port-forward -n agentgateway-system svc/ai-gateway 8080:80"
echo ""
echo "Test the Anthropic LLM backend:"
echo "  curl -X POST http://localhost:8080/v1/messages \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{"
echo "      \"model\": \"claude-sonnet-4-20250514\","
echo "      \"max_tokens\": 100,"
echo "      \"messages\": [{"
echo "        \"role\": \"user\","
echo "        \"content\": \"What is an AI gateway?\""
echo "      }]"
echo "    }'"
echo ""
