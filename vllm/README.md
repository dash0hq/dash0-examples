# vLLM + OpenTelemetry + Dash0

Observe a vLLM inference server end-to-end using OpenTelemetry — distributed traces from a FastAPI RAG application through to the vLLM engine, plus Prometheus metrics scraped and forwarded to Dash0.

## What this demonstrates

- Distributed traces spanning a FastAPI RAG app and the vLLM inference server, connected via W3C trace context propagation
- GenAI semantic convention attributes (`gen_ai.provider.name`, `gen_ai.request.model`, token usage) on LLM spans
- vLLM's native OTLP trace export via `--otlp-traces-endpoint` (no code changes to the server)
- Prometheus metrics from vLLM (`vllm:*` metrics family) scraped by the OTel Collector and forwarded to Dash0
- Custom RAG app metrics (`rag_queries_total`, `rag_query_duration_seconds`) via `prometheus-client`
- OTel Collector acting as a unified pipeline for both traces (OTLP) and metrics (Prometheus scrape)

## Technologies

- [vLLM](https://docs.vllm.ai/) — high-throughput LLM inference server with native OTel support
- [OpenTelemetry](https://opentelemetry.io/) — distributed tracing and metrics
- Python / FastAPI — RAG application with manual OTel instrumentation
- Docker Compose — local orchestration
- [Dash0](https://www.dash0.com/) — observability backend

## Prerequisites

- Docker and Docker Compose
- Dash0 account with an auth token
- NVIDIA GPU (the vLLM Docker image is CUDA-compiled; a `g4dn.xlarge` on AWS with one T4 is sufficient for testing)

## Quick Start

1. **Set your Dash0 credentials** in the root `.env` file:
   ```bash
   DASH0_AUTH_TOKEN=your_auth_token_here
   DASH0_DATASET=default
   DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=ingress.eu-west-1.aws.dash0.com
   DASH0_ENDPOINT_OTLP_GRPC_PORT=4317
   ```
   Get your auth token from [Dash0 settings](https://app.dash0.com/settings).

2. **Run the setup script** from the `vllm/` directory:
   ```bash
   cd vllm
   ./00_setup.sh
   ```
   This validates your environment (Docker, NVIDIA GPU, credentials) and starts all services.

3. **Wait for vLLM to finish loading the model.** On first run it downloads `facebook/opt-125m` (~500 MB) and then loads it into GPU memory. Follow the logs:
   ```bash
   docker compose logs -f vllm
   ```
   Look for this line before sending requests:
   ```
   vllm-server  | INFO:     Application startup complete.
   ```
   This typically takes 2–5 minutes on first run.

4. **Send test queries:**
   ```bash
   python scripts/send-request.py
   ```
   Or manually:
   ```bash
   curl -X POST http://localhost:8001/query \
     -H "Content-Type: application/json" \
     -d '{"query": "What is OpenTelemetry?"}'
   ```

5. **View telemetry in Dash0:**
   - **Traces**: filter by `service.name = "rag-app"` or `service.name = "vllm-server"` to see the full request flow
   - **Metrics**: search for `vllm:*` (inference metrics) or `rag_queries_total` (RAG request counter)

## What you'll see in Dash0

Each query to the RAG app produces a distributed trace with spans across two services:

**rag-app**
- `POST /query` — auto-instrumented HTTP server span (FastAPIInstrumentor)
- `rag.query` — top-level RAG span with GenAI attributes
- `rag.retrieve` — mock document retrieval with `rag.context.length`
- `rag.generate` — outbound call to vLLM; injects W3C `traceparent` header

**vllm-server**
- `POST /v1/completions` — vLLM request span, linked via the propagated `traceparent` header
- `llm_request` — inference span with `gen_ai.*` attributes (model, token counts, finish reason)

The metrics pipeline collects vLLM's built-in Prometheus metrics (request throughput, token counts, cache utilisation) alongside the RAG app's custom counters.

## Architecture

```
                  ┌─────────────────────┐
  curl / script ──▶   rag-app :8001     │
                  │  (FastAPI + OTel)    │
                  └────────┬────────────┘
                           │ HTTP + traceparent header
                           ▼
                  ┌─────────────────────┐
                  │  vllm-server :8000   │
                  │  facebook/opt-125m   │
                  └────────┬────────────┘
                           │
              ┌────────────┴──────────────┐
              │ OTLP traces (gRPC :4317)  │ Prometheus scrape
              │ (both services → collector)│ (/metrics on :8000, :8001)
              ▼                           ▼
     ┌──────────────────────────────────────────┐
     │         OTel Collector :4317             │
     └──────────────────┬───────────────────────┘
                        │ OTLP gRPC
                        ▼
                  ┌──────────┐
                  │  Dash0   │
                  └──────────┘
```

## Cleanup

```bash
./01_cleanup.sh
```

This stops all containers and optionally removes the cached model weights (~500 MB Docker volume).

## References

- [vLLM metrics and tracing docs](https://docs.vllm.ai/en/latest/deployment/metrics.html)
- [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/)
- [OTel Collector Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/prometheusreceiver)
- [Dash0](https://www.dash0.com/)
