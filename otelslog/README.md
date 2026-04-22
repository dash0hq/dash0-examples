# Go Structured Logging with log/slog and OpenTelemetry

Companion repository for the Dash0 guide on structured logging in Go using
`log/slog` and the OpenTelemetry (OTel) slog bridge.

This playground runs a small Go service alongside an OpenTelemetry Collector so
you can see structured log output and its OTel-normalized equivalent side by
side — and watch how trace context flows automatically into log records.

## What's inside

The Go application in `main.go` demonstrates:

- Setting up an OTel logger provider and tracer provider with OTLP HTTP export.
- Bridging `log/slog` to OTel using
  [`go.opentelemetry.io/contrib/bridges/otelslog`](https://pkg.go.dev/go.opentelemetry.io/contrib/bridges/otelslog).
- Fanning log records out to both OTel and JSON on stderr using
  `slog.NewMultiHandler`.
- Automatic trace correlation: log records emitted inside a span carry the
  span's trace ID and span ID with no extra code.

The Collector is configured with the OTLP receiver and the `debug` exporter, so
every log record and trace the application emits is printed in the OTel format
to the Collector's stdout.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- [Go](https://go.dev/dl/) 1.24 or later (only needed to modify the source)

## Quick start

1. Start the Collector:

```bash
docker compose up -d
```

2. Run the Go application:

```bash
go run .
```

You'll see two streams of output:

- The application emits structured JSON logs to stderr.
- The Collector prints the same events in the OTel log format after receiving
  them via OTLP.

Comparing the two is the fastest way to see how `slog` records are transformed
as they flow through an OTel pipeline — and how `TraceId` and `SpanId` appear
automatically on records emitted inside a span.

## Sending logs and traces to Dash0

The Collector config in `otelcol.yaml` already includes an `otlp_http/dash0`
exporter. Set your credentials as environment variables and relaunch:

```bash
export DASH0_ENDPOINT=ingress.eu-west-1.aws.dash0.com
export DASH0_AUTH_TOKEN=<your-auth-token>
export DASH0_DATASET=<your-dataset>

docker compose up -d --force-recreate
```

Then update `otelcol.yaml` to use environment variable substitution:

```yaml
exporters:
  otlp_http/dash0:
    endpoint: https://${env:DASH0_ENDPOINT}
    headers:
      Authorization: Bearer ${env:DASH0_AUTH_TOKEN}
      Dash0-Dataset: ${env:DASH0_DATASET}

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlp_http/dash0]
    logs:
      receivers: [otlp]
      exporters: [otlp_http/dash0]
```

Sign up for a free trial at [dash0.com](https://www.dash0.com/sign-up) to get
your ingress endpoint and auth token.

## Cleanup

```bash
docker compose down
```
