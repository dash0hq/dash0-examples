# NGINX Logs

This repo demonstrates an OpenTelemetry pipeline for NGINX logs covering:

- Structured JSON logging for reliable parsing.
- Log sampling to cut down on log noise and cost.
- Robust error log parsing.
- Full integration with the OpenTelemetry ecosystem.

**Full tutorial**: [Mastering NGINX Logs with JSON and OpenTelemetry](https://www.dash0.com/guides/nginx-logs)

## Prerequisites

- Docker

## Getting started

1. Bring up the services with:

```bash
docker compose up -d
```

2. Check your OpenTelemetry-compliant NGINX logs in the console with:

```bash
docker compose logs -f otelcol --no-log-prefix
```

## Sending logs to Dash0

Retrive your Dash0 credentials and update the relevant fields in `otelcol.yaml`.

Then add `otlphttp/dash0` to your `exporters` config.
