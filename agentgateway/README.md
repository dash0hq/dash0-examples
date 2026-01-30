# Agentgateway with OpenTelemetry

An AI-first Kubernetes Gateway API demo with native Anthropic integration and full observability using OpenTelemetry and Dash0.

## What it does

- Creates a multi-node Kind cluster with agentgateway (Rust-based AI Gateway API implementation)
- Deploys local observability stack: Jaeger, Prometheus, and OpenSearch
- Configures distributed tracing with GenAI semantic conventions for LLM calls
- Native Anthropic integration using AgentgatewayBackend CRD (no custom proxy code)
- Deploys OpenTelemetry Collectors with dual export to Dash0 and local stack
- Includes prompt guard to reject sensitive data (emails) and prompt enrichment
- Scrapes GenAI metrics (token usage, operation duration) from agentgateway

## Prerequisites

- Docker
- Kind
- kubectl
- Helm 3
- Dash0 account with API token
- Anthropic API key

## Quick Start

1. **Configure environment variables:**
   ```bash
   # From the root directory (dash0-examples)
   cp .env.template .env
   # Edit .env with your Dash0 credentials and add:
   # ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
   ```

2. **Deploy everything:**
   ```bash
   ./00_run.sh
   ```

3. **Access the gateway:**
   ```bash
   kubectl port-forward -n agentgateway-system svc/ai-gateway 8080:80
   ```

4. **Test the Anthropic integration:**
   ```bash
   # Valid request (with auto-injected system prompt)
   curl -X POST http://localhost:8080/v1/messages \
     -H 'Content-Type: application/json' \
     -d '{
       "model": "claude-sonnet-4-20250514",
       "max_tokens": 80,
       "messages": [{
         "role": "user",
         "content": "What is 2+2?"
       }]
     }'

   # Rejected by prompt guard (contains email)
   curl -X POST http://localhost:8080/v1/messages \
     -H 'Content-Type: application/json' \
     -d '{
       "model": "claude-sonnet-4-20250514",
       "max_tokens": 50,
       "messages": [{
         "role": "user",
         "content": "Email user@example.com"
       }]
     }'
   ```

## Accessing Telemetry

The demo sends telemetry to both Dash0 (primary cloud backend) and a local observability stack for offline inspection.

### Dash0 (Primary)
Log in to your Dash0 dashboard to view:
- **Traces**: Filter by `service.name = "ai-gateway"` - includes GenAI semantic conventions
- **Metrics**: Search for `agentgateway_gen_ai_*` metrics (token usage, operation duration)
- **Logs**: Structured logs with trace IDs and GenAI attributes

### Local Observability Stack

**Jaeger (Traces):**
```bash
kubectl port-forward -n default svc/jaeger-query 16686:16686
```
Visit: http://localhost:16686

**Prometheus (Metrics):**
```bash
kubectl port-forward -n default svc/prometheus 9090:9090
```
Visit: http://localhost:9090
Query examples:
- `agentgateway_gen_ai_client_token_usage_count`
- `rate(agentgateway_gen_ai_client_token_usage_sum[5m])`

**OpenSearch Dashboards (Logs):**
```bash
kubectl port-forward -n default svc/opensearch-dashboards 5601:5601
```
Visit: http://localhost:5601
- Username: `admin`
- Password: `SecureP@ssw0rd123`

**View structured logs:**
```bash
kubectl logs -n agentgateway-system deployment/ai-gateway --tail=50 | grep gen_ai
```

## Cleanup

```bash
./01_cleanup.sh
```

## References

- [Agentgateway Documentation](https://agentgateway.dev/)
- [Agentgateway Anthropic Integration](https://agentgateway.dev/docs/kubernetes/latest/llm/providers/anthropic/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [OpenTelemetry](https://opentelemetry.io/)
- [GenAI Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/)
- [Dash0](https://www.dash0.com/)
