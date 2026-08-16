# Claude Code Monitoring with OpenTelemetry

This demo collects Claude Code telemetry with OpenTelemetry and provides a
local observability stack for exploring usage, cost, activity, logs, and traces.

The stack includes:

- An OpenTelemetry Collector that receives OTLP over gRPC.
- Prometheus for Claude Code metrics.
- VictoriaLogs for Claude Code events.
- Jaeger for Claude Code traces.
- Grafana with provisioned data sources and a Claude Code metrics dashboard.

## Prerequisites

- Docker and Docker Compose
- [Claude Code](https://code.claude.com/docs/en/overview)

## Quick start

1. Start the observability stack:

```bash
docker compose up -d
```

2. Enable Claude Code telemetry and send it to the local Collector:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_TRACES_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

3. Start a Claude Code session and submit a prompt:

```bash
claude
```

Metrics are exported every 60 seconds by default. For quicker feedback while
testing, set `OTEL_METRIC_EXPORT_INTERVAL=10000` before starting Claude Code.

4. Open [Grafana](http://localhost:3000) and browse to **Dashboards > AI Agents
   > Claude Code Metrics (Prometheus)**.

Grafana is configured for anonymous admin access in this local demo, so no
login is required. Its Explore view also includes the provisioned
VictoriaLogs and Jaeger data sources. You can open the Jaeger UI directly at
[http://localhost:16686](http://localhost:16686).

Claude Code redacts prompt text and detailed tool content from telemetry by
default. See the [Claude Code monitoring documentation](https://code.claude.com/docs/en/monitoring-usage)
for the available telemetry signals, privacy controls, and configuration
options.

## How it works

Claude Code exports metrics, events, and beta traces to the Collector on port
4317. The Collector routes each signal to its local backend:

- Metrics to Prometheus at `http://localhost:9090`.
- Events to VictoriaLogs at `http://localhost:9428`.
- Traces to Jaeger at `http://localhost:16686`.

Grafana connects to all three backends and automatically loads the included
Claude Code dashboard.

## Troubleshooting

Check that every service is running:

```bash
docker compose ps
```

Watch the Collector for incoming telemetry and export errors:

```bash
docker compose logs -f otelcol
```

If no telemetry arrives, run `claude --debug` and check its debug output for
OpenTelemetry export errors.

## Cleanup

```bash
docker compose down
```

To also remove the local Prometheus, VictoriaLogs, and Grafana data volumes:

```bash
docker compose down -v
```
