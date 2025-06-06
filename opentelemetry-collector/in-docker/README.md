# OpenTelemetry Collector in Docker

This example demonstrates how to run the OpenTelemetry Collector in Docker and send spans to it.

## Prerequisites

- Docker installed on your machine
- A Dash0 account with API credentials

## Setup

1. Copy the `.env.template` file to `.env` in the project root:
   ```bash
   cp ../../.env.template ../../.env
   ```

2. Update the `.env` file with your Dash0 credentials:
   - `DASH0_AUTH_TOKEN` - Your Dash0 API token
   - `DASH0_DATASET` - The dataset to send telemetry data to
   - Other environment variables can be left as their defaults or customized

## Running the Collector

Run the OpenTelemetry Collector in a Docker container:

```bash
./00_run.sh
```

This will:
- Start the OpenTelemetry Collector in Docker
- Expose ports 4317 (gRPC) and 4318 (HTTP) for receiving telemetry
- Mount the local `config.yaml` into the container
- Pass environment variables from your `.env` file to the container

## Sending Test Spans

To test the collector, you can send two sample spans (one of which will be dropped):

```bash
./01_send-spans.sh
```

This script sends a sample trace span to the collector using the HTTP endpoint (port 4318). The collector will:
1. Process the span with the configured batch processor
2. Filter matching spans
3. Output the span to the debug exporter (visible in logs)
4. Forward the span to Dash0 using the OTLP exporter

## Sending Test Logs

The collector is also configured to transform logs using the transform processor:

```bash
./02_send-logs.sh
```

This script sends a sample log to the collector using the HTTP endpoint (port 4318). The collector will:
1. Process the log with the configured batch processor
2. Set the missing timestamp fields
3. Output the span to the debug exporter (visible in logs)
4. Forward the span to Dash0 using the OTLP exporter
