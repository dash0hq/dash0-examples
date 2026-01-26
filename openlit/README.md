# OpenLIT Auto-Instrumentation with Anthropic + Dash0

Demo of OpenLIT operator for zero-code auto-instrumentation of LLM applications, sending traces to both Dash0 and OpenLIT UI.

## Prerequisites

- Docker, kubectl, Helm, kind
- Anthropic API key
- Dash0 account

## Setup

### 1. Configure environment

Uses the shared `.env` file in the repository root. Ensure these values are set:

```bash
ANTHROPIC_API_KEY=sk-ant-your-key-here
DASH0_AUTH_TOKEN=Bearer auth_your_token_here
DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=ingress.eu-west-1.aws.dash0.com
DASH0_ENDPOINT_OTLP_GRPC_PORT=4317
```

### 2. Deploy

```bash
./00_run.sh
```

### 3. Test

Send a request to the app:

```bash
kubectl port-forward svc/openlit-demo-app -n demo 8080:8080
```

In another terminal:
```bash
curl -X POST http://localhost:8080/chat -H "Content-Type: application/json" -d '{"message": "Hello!"}'
```

## Viewing Results

### Dash0
Navigate to Traces and filter by:
- `service.name=openlit-demo-app`

### OpenLIT UI
Port forward to access the local OpenLIT dashboard:
```bash
kubectl port-forward svc/openlit -n openlit 3000:3000
```
Then open http://localhost:3000 in your browser.

You'll see automatically captured traces of Anthropic API calls in both UIs without any manual instrumentation code.

## How It Works

1. OpenLIT Operator watches for pods with label `instrumentation: openlit`
2. When found, it injects instrumentation into the container
3. The instrumented app sends OTLP traces to the OpenTelemetry Collector
4. OTel Collector receives traces and forwards to both:
   - Dash0 (cloud observability platform)
   - OpenLIT Platform (local UI for trace visualization)

## Cleanup

```bash
./01_cleanup.sh
```

Removes the Kind cluster and all resources.
