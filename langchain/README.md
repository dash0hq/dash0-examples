# LangChain + Anthropic + OpenTelemetry

Demos showing manual vs auto-instrumentation for LangChain applications with OpenTelemetry.

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

### Run Individual Demos

**Manual instrumentation:**
```bash
cd manual
./run.sh
```

**Auto-instrumentation:**
```bash
cd auto
./run.sh
```

### Cleanup

```bash
./01_cleanup.sh
```

## What's Included

Both demos show:
- Simple chat with Anthropic
- Chain composition (prompt | llm | parser)
- Streaming responses

**Manual** (`manual/`): Explicit OpenTelemetry code, custom spans, full control

**Auto** (`auto/`): Zero-code instrumentation via `opentelemetry-instrument`

## Viewing Results

**Dash0:** Navigate to Traces and filter by:
- `langchain-anthropic-demo` (manual)
- `langchain-anthropic-auto` (auto)
