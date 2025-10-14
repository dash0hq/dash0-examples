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

The collector is configured with tail sampling policies organized into **policy groups**. 
Each test script targets a specific policy group using the `policy.group` resource attribute, ensuring that traces are evaluated only by their designated policy group.

### Policy Groups:

1. **error-sampling**: Samples all traces containing spans with ERROR status AND `policy.group="error-sampling"`
2. **latency-sampling**: Samples traces with latency exceeding 1000ms AND `policy.group="latency-sampling"`
3. **probabilistic-sampling**: Samples 50% of traces with `policy.group="probabilistic-sampling"`

The tail sampling processor waits for 5 seconds to collect all spans in a trace before making a sampling decision.

### How Policy Grouping Works

Policy groups are implemented using composite `and` policies that combine:
- The actual sampling logic (error status, latency threshold, etc.)
- A resource attribute check for `policy.group`

This ensures that each trace is only evaluated by its designated policy group, preventing cross-policy interference even though all traces flow through the same collector.

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

### 2. Send multiple non-sampled spans in a single trace (error-sampling group)

```bash
./02_send-spans-not-sampled.sh
```

Sends three spans (frontend, backend-billing, backend-api) with the same trace ID and `policy.group="error-sampling"`, all with OK/UNSET status. The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Evaluate against the error-traces-policy:
   - Policy group matches ✅ (`policy.group="error-sampling"`)
   - Error status check fails ❌ (no ERROR spans)
3. Drop the entire trace because the policy requires BOTH conditions (AND logic)
4. Demonstrates how a trace can match the policy group but still be dropped due to unmet sampling conditions

### 3. Send spans with an error (error-sampling group)

```bash
./03_send-spans-error-sampled.sh
```

Sends three spans with the same trace ID and `policy.group="error-sampling"`, where the last span has ERROR status. The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Match the error-sampling policy group due to policy.group attribute
3. Detect ERROR status and sample the entire trace (error-traces-policy)
4. Filter matching spans using the filter processor
5. Apply transformations with the transform processor
6. Batch the spans with the batch processor
7. Output to the debug exporter (visible in logs)
8. Forward to Dash0 using the OTLP exporter

### 4. Send spans with high latency (latency-sampling group)

```bash
./04_send-spans-high-latency-sampled.sh
```

Sends three spans with the same trace ID and `policy.group="latency-sampling"`, with 1+ second delays between spans. The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Match the latency-sampling policy group due to policy.group attribute
3. Calculate trace latency and sample due to slow-traces-policy (> 1000ms)
   - **Note**: Latency is calculated based on the trace duration - the difference between the earliest start time and latest end time across all spans in the trace, without considering what happened in between
4. Filter matching spans using the filter processor
5. Apply transformations with the transform processor
6. Batch the spans with the batch processor
7. Output to the debug exporter (visible in logs)
8. Forward to Dash0 using the OTLP exporter

### 5. Send spans with probabilistic sampling (probabilistic-sampling group)

```bash
./05_send-spans-probabilistic-sampled.sh
```

Sends three spans with the same trace ID and `policy.group="probabilistic-sampling"`. The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Match the probabilistic-sampling policy group due to policy.group attribute
3. Sample 50% of traces based on probabilistic sampling
4. **Note**: Run this script multiple times to observe the sampling behavior - approximately half of the traces will be sampled
