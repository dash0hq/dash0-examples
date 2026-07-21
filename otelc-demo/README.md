# OpenTelemetry Go Compile-Time Instrumentation Demo

This starter project accompanies the Dash0 guide to compile-time Go
instrumentation with `otelc`.

The service uses:

- `net/http` for HTTP server and client operations
- `database/sql` with an in-memory SQLite database
- `log/slog` for structured application logs

## Requirements

- Go 1.22 or later
- Docker with Docker Compose
- `curl`
- `otelc` for the instrumented build

## Run without instrumentation

```bash
go mod tidy
go build -o otelc-demo .
./otelc-demo
```

In another terminal:

```bash
curl http://localhost:8080/
curl http://localhost:8080/fetch
```

## Run with compile-time instrumentation

Install `otelc`:

```bash
go install go.opentelemetry.io/otelc/tool/cmd/otelc@latest
```

Start the OpenTelemetry Collector:

```bash
docker compose up collector
```

Build and run the instrumented service in another terminal:

```bash
otelc go build -o otelc-demo .

export OTEL_SERVICE_NAME=otelc-demo
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
./otelc-demo
```

Generate telemetry:

```bash
curl http://localhost:8080/
curl http://localhost:8080/
curl http://localhost:8080/fetch
```

The Collector prints the resulting traces, metrics, and logs to its terminal.
