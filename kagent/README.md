# Kagent with Anthropic + OpenTelemetry + Dash0

[Kagent](https://kagent.dev) demo with OpenTelemetry tracing, using Anthropic for LLM inference.

## Prerequisites

- Docker, kubectl, Helm, kind
- Anthropic API key
- Dash0 account

## Setup

### 1. Configure environment

The kagent demo uses the shared `.env` file in the repository root:

```bash
# Ensure ../.env exists with these values
ANTHROPIC_API_KEY=sk-ant-your-key-here
DASH0_AUTH_TOKEN=Bearer auth_your_token_here
DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=ingress.eu-west-1.aws.dash0.com
DASH0_ENDPOINT_OTLP_GRPC_PORT=4317
DASH0_MCP_TOKEN=auth_your_mcp_token_here  # For MCP server integration
```

### 2. Deploy

```bash
./00_run.sh
```

### 3. Access kagent UI

```bash
kubectl port-forward svc/kagent-ui -n kagent 8080:8080
```

Open http://localhost:8080

## Using the Client App Frontend

The demo includes a web frontend that lets you interact with the observability agent:

1. **Port forward the client app**:
   ```bash
   kubectl port-forward svc/kagent-client-app -n kagent 8000:8000
   ```

2. **Open the web UI**: Navigate to http://localhost:8000

3. **Ask questions about your observability data**:
   - "What services are available?"
   - "Show me recent errors"
   - "What's the latency for the kagent service?"
   - "Find correlated logs for failing requests"

The agent will use the appropriate Dash0 MCP tools to query your observability data and return formatted responses. Every interaction creates distributed traces that you can view in Dash0 by filtering for `service.name=kagent*`.

## Changing the Model

Edit `values.yaml` to use a different Anthropic model:

```yaml
providers:
  default: anthropic
  anthropic:
    provider: Anthropic
    model: claude-sonnet-4-20250514  # or any other Anthropic model
    apiKeySecretRef: anthropic-api-key
    apiKeySecretKey: api-key
```

Then upgrade:
```bash
helm upgrade kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace kagent \
    -f values.yaml
```

## Viewing Results

**Dash0**: Navigate to Traces and filter by:
- `service.name=kagent*`

You'll see traces for all kagent operations including LLM calls to Anthropic.

## Deployed Components

The setup deploys:
- **Observability Agent**: An agent with Dash0 MCP tools for querying logs, traces, and metrics (`agent-observability.yaml`)
- **Dash0 MCP Server**: Remote MCP server connection to Dash0 API (`mcp-dash0.yaml`)
- **Client App**: A FastAPI web application that provides a frontend for querying the observability agent

## Testing the Client App via API

You can also interact with the client app programmatically via its REST API:

Send a query using curl:
```bash
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What services are available?"}'
```

### What happens:
1. Client app receives the query
2. Forwards the query to the kagent observability-agent via the A2A API
3. The observability-agent uses Dash0 MCP tools to query your observability data
4. The agent uses Anthropic Claude to process and format the response
5. Returns the agent's response

### Trace in Dash0:
You'll see a distributed trace showing:
```
Client App (FastAPI)
    → kagent observability-agent
        → Dash0 MCP Tools (getServiceCatalog, getSpans, etc.)
        → Anthropic API (Claude)
```

## Observability Agent with Dash0 MCP

The observability agent can query your Dash0 data using MCP (Model Context Protocol) tools.

### Using the Observability Agent via Kagent UI:

As an alternative to the client app frontend, you can also interact with the agent directly through the kagent UI:

1. Open the kagent UI at http://localhost:8080
2. Select the **observability-agent** from the available agents
3. Ask questions directly in the kagent interface

The agent will use the appropriate Dash0 MCP tools to answer your questions with real observability data.

## Cleanup

```bash
./01_cleanup.sh
```

Removes the Kind cluster and all resources.
