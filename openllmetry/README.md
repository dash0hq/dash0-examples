# OpenLLMetry + Anthropic + Dash0

Demo showing OpenLLMetry instrumentation for LLM applications with Anthropic, sending traces to Dash0.

## What is OpenLLMetry?

OpenLLMetry (Traceloop SDK) is a lightweight, open-source OpenTelemetry-based observability SDK for LLM applications. It provides automatic instrumentation for various LLM providers, vector databases, and frameworks with minimal configuration.

## Prerequisites

- Python 3.9+
- [uv](https://docs.astral.sh/uv/)
- Docker
- Anthropic API key
- Dash0 account

## Quick Start

The `.env` file in the repository root already has the required variables. Make sure these are set:

```bash
ANTHROPIC_API_KEY=sk-ant-your-key-here
DASH0_AUTH_TOKEN=auth_your_token_here
DASH0_DATASET=default
DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=ingress.eu-west-1.aws.dash0.com
DASH0_ENDPOINT_OTLP_GRPC_PORT=4317
```

### Setup

```bash
./00_setup.sh
```

## Demo Options

This repository includes three different demo approaches:

### 1. Enhanced Demo with Custom Spans (Default)

Shows complex traces with custom parent/child spans.

```bash
./run.sh
```

Features:
- Custom parent spans for workflows (process_customer_query, rag_workflow)
- Nested child spans (analyze_sentiment, generate_response)
- HTTP instrumentation showing underlying API calls
- Custom attributes and events
- Multiple LLM calls in hierarchical workflows

### 2. Pure Auto-Instrumentation Demo

Uses only automatic instrumentation with no manual spans.

```bash
./run_auto.sh
```

Features:
- Zero manual span creation
- Automatic LLM call tracing via Traceloop SDK
- Automatic HTTP tracing via opentelemetry-instrument
- Simpler code, still captures all telemetry

### 3. FastAPI Server Demo

FastAPI application with auto-instrumentation.

```bash
./run_fastapi.sh
```

Features:
- HTTP server spans for incoming requests
- LLM call spans for Anthropic API
- RESTful API endpoint: POST /analyze
- Interactive API docs at http://localhost:8080/docs

Test the API:
```bash
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"query": "This is amazing!"}'
```

## Cleanup

```bash
./01_cleanup.sh
```

## Viewing Results

Navigate to Traces in Dash0 and filter by:
- `service.name=openllmetry-demo` (for CLI demos)
- `service.name=openllmetry-fastapi-demo` (for FastAPI demo)

Trace details include:
- Complete trace hierarchy with parent/child relationships
- API call duration for each span
- Token usage (input/output tokens)
- Model information
- Full prompt and response content
- HTTP request details (method, URL, status code)


