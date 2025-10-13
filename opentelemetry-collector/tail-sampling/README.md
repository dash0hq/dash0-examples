# OpenTelemetry Collector with Tail Sampling

This example demonstrates how to run the OpenTelemetry Collector in Docker with tail-based sampling policies. 
Tail sampling makes sampling decisions after all spans in a trace have been received, allowing you to sample based on trace-level characteristics like errors or high latency.

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

## Tail Sampling Configuration

The collector is configured with the following tail sampling policies:

1. **Error Traces Policy**: Samples all traces containing spans with ERROR status
2. **Slow Traces Policy**: Samples traces with latency exceeding 1000ms

The tail sampling processor waits for 5 seconds to collect all spans in a trace before making a sampling decision.

## Testing Tail Sampling

You can test the tail sampling behavior with the following scripts:

### 1. Send spans that won't be sampled

```bash
./01_send-not-sampled-spans.sh
```

Sends two spans with UNSET and OK status codes. These will not be sampled since they don't match any policy. The collector will:
1. Evaluate the spans with the tail sampling processor (waits 5s for decision)
2. Drop the spans as they don't match sampling policies
3. No further processing or export occurs

### 2. Send multiple non-sampled spans in a single trace

```bash
./02_send-spans-not-sampled.sh
```

Sends three spans (frontend, backend-billing, backend-api) with the same trace ID, all with OK/UNSET status. The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Evaluate against tail sampling policies
3. Drop the entire trace as it doesn't match any policy

### 3. Send spans with an error (sampled)

```bash
./03_send-spans-error-sampled.sh
```

Sends three spans with the same trace ID, where the last span has ERROR status. The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Detect ERROR status and sample the entire trace (error-traces-policy)
3. Filter matching spans using the filter processor
4. Apply transformations with the transform processor
5. Batch the spans with the batch processor
6. Output to the debug exporter (visible in logs)
7. Forward to Dash0 using the OTLP exporter

### 4. Send spans with high latency (sampled)

```bash
./04_send-spans-high-latency-sampled.sh
```

Sends three spans with the same trace ID, with 1+ second delays between spans. The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Calculate trace latency and sample due to slow-traces-policy (> 1000ms)
3. Filter matching spans using the filter processor
4. Apply transformations with the transform processor
5. Batch the spans with the batch processor
6. Output to the debug exporter (visible in logs)
7. Forward to Dash0 using the OTLP exporter
