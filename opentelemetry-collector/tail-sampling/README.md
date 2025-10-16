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
# Run with default config.yaml
./00_run.sh

# Or specify a different config file
./00_run.sh config-composite.yaml
./00_run.sh config-first-match.yaml
```

This will:
- Start the OpenTelemetry Collector in Docker
- Expose ports 4317 (gRPC) and 4318 (HTTP) for receiving telemetry
- Mount the specified config file (or `config.yaml` by default) into the container
- Pass environment variables from your `.env` file to the container

## Tail Sampling Configuration

This example includes **four configuration files** demonstrating different sampling approaches:

### 1. `config.yaml` (Default - Policy Groups)
The main configuration using **policy groups** for isolated sampling strategies.
Each test script (01-06) targets a specific policy group using the `policy.group` resource attribute.

**Policy Groups:**
1. **error-sampling**: Samples all traces containing spans with ERROR status AND `policy.group="error-sampling"`
2. **latency-sampling**: Samples traces with latency exceeding 1000ms AND `policy.group="latency-sampling"`
3. **probabilistic-sampling**: Samples 50% of traces with `policy.group="probabilistic-sampling"`
4. **ottl-condition-sampling**: Samples traces matching OTTL conditions AND `policy.group="ottl-condition-sampling"`

The tail sampling processor waits for 5 seconds to collect all spans in a trace before making a sampling decision.

### 2. `config-first-match.yaml` (Priority-Based Sampling)
Demonstrates `sample_on_first_match: true` with priority-ordered policies (errors > latency > important endpoints > probabilistic baseline). This config short-circuits evaluation as soon as a policy samples a trace, improving performance for high-volume systems.

### 3. `config-composite.yaml` (Rate Allocation)
Demonstrates the **composite policy type** with rate allocation across sub-policies. Use this when you need to guarantee sampling rates for different trace categories while enforcing a total throughput limit.

**Configuration:**
- 50% (2 spans/s) for errors (`http.status_code >= 400`)
- 50% (2 spans/s) for mutations (`http.method` in [POST, PUT, DELETE])
- Total: 4 spans/s (intentionally low for testing)

**Key differences from other policies:**
- Cannot be wrapped in an `and` policy (evaluates ALL traces globally, not policy-group-based)
- "First match wins" - array order determines priority
- Rate limits prevent any category from consuming all capacity

### 4. `config-decision-cache.yaml` (Decision Cache Testing)
Demonstrates the **decision cache** feature with:
- `num_traces: 1` to force trace eviction for testing purposes
- `decision_cache` enabled with cache sizes of 10000 for both sampled and non-sampled decisions

This configuration is specifically designed for testing how the collector handles late-arriving spans using cached sampling decisions. Used by test script 07.

### Configuration Options

#### `decision_cache`

The `decision_cache` configuration option enables caching of sampling decisions after traces have been evaluated. This is crucial for handling **late-arriving spans** - spans that arrive after the trace has already been evaluated and potentially evicted from memory.

**Problem without decision cache:**
- Tail sampling processor holds traces in memory (`num_traces` limit) while waiting for all spans
- After `decision_wait` expires, a sampling decision is made and the trace is processed
- If a late span arrives after the trace is evicted from memory, the collector doesn't know what to do with it
- Without cache: late span is treated as a new trace and may be dropped or re-evaluated incorrectly

**Solution with decision cache:**
- After making a sampling decision, the decision is cached with the trace ID as the key
- Cache keeps both "sampled" and "not sampled" decisions separately
- When a late-arriving span comes in, the collector looks up the trace ID in the cache
- If found, the cached decision is applied (sample or drop) without re-evaluating policies
- This ensures consistent handling of all spans in a trace, regardless of arrival order

**Configuration:**
```yaml
decision_cache:
  sampled_cache_size: 10000      # Number of "sampled" decisions to cache
  non_sampled_cache_size: 10000  # Number of "not sampled" decisions to cache
```

#### `sample_on_first_match`

The `sample_on_first_match` configuration option controls when the tail sampling processor stops evaluating policies.

**IMPORTANT: This flag ONLY stops evaluation on "Sampled" decisions, NOT on "NotSampled" (drop) decisions.**

**Default: `false` (Evaluate all policies)**
- The processor evaluates ALL configured policies for each trace
- Collects all decisions and uses the most permissive result
- If ANY policy decides to sample the trace, it will be sampled
- Dropping decisions don't prevent other policies from sampling
- Best for scenarios where you want multiple independent sampling criteria
- Example: A trace with both an error AND high latency will be sampled by either the error-sampling OR latency-sampling policy

**When set to `true` (Stop on first "Sampled" decision)**
- The processor stops evaluating as soon as a policy decides to SAMPLE
- Policies that decide NOT to sample (drop) don't stop evaluation
- Subsequent policies are skipped only after a positive sampling decision
- Policies are evaluated in the order they appear in the configuration
- More efficient when early policies sample high-priority traces
- Best for priority-based sampling where you want to capture important traces quickly

**Example Scenarios:**

*Scenario 1: `sample_on_first_match: false` (default)*
```yaml
policies:
  - name: error-policy
    type: status_code
    status_code: { status_codes: ["ERROR"] }

  - name: latency-policy
    type: latency
    latency: { threshold_ms: 1000 }
```
**Trace with error:** Both policies are evaluated. Error-policy says "sample", latency-policy might say "sample" or "not sample". Final decision: **Sampled** (at least one policy matched).

**Trace without error but slow:** Both policies are evaluated. Error-policy says "not sample", latency-policy says "sample". Final decision: **Sampled** (latency policy matched).

**Trace without error and fast:** Both policies are evaluated. Both say "not sample". Final decision: **Not Sampled**.

*Scenario 2: `sample_on_first_match: true`*
```yaml
policies:
  - name: error-policy  # Evaluated first
    type: status_code
    status_code: { status_codes: ["ERROR"] }

  - name: latency-policy  # Evaluated ONLY if error-policy returns "not sample"
    type: latency
    latency: { threshold_ms: 1000 }
```
**Trace with error:** Error-policy says "sample". Evaluation STOPS immediately. Latency-policy is never checked. Final decision: **Sampled**.

**Trace without error but slow:** Error-policy says "not sample" (no error). Evaluation CONTINUES. Latency-policy is checked and says "sample". Final decision: **Sampled**.

**Trace without error and fast:** Error-policy says "not sample". Evaluation continues. Latency-policy says "not sample". Final decision: **Not Sampled**.

**Key Insight:** With `sample_on_first_match: true`, you can't prevent a trace from being sampled by a later policy if earlier policies drop it. The flag only short-circuits on positive sampling decisions.

**When to use `sample_on_first_match: true`:**
- **Performance optimization ONLY**: Reduce CPU usage by skipping remaining policy evaluations once a trace is already going to be sampled
- You expect many traces to match early policies (errors, critical endpoints) and want to avoid wasting CPU checking remaining policies
- You don't need observability into ALL policies that matched (only the first one that sampled)

**Important Note**: Since the final decision is always "sample if ANY policy says sample" (most permissive wins), this flag ONLY affects:
1. **Performance**: Skip unnecessary policy evaluations to save CPU
2. **Observability**: With `false`, you can see ALL policies that matched; with `true`, you only see the first match

The sampling decision outcome is the SAME either way. This is purely a performance vs observability trade-off.

### How Policy Grouping Works

Policy groups are implemented using `and` policies that combine:
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

### 6. Send spans with OTTL condition sampling (ottl-condition-sampling group)

```bash
./06_send-spans-ottl-condition-sampled.sh
```

Sends two separate traces with `policy.group="ottl-condition-sampling"`, demonstrating OpenTelemetry Transformation Language (OTTL) condition matching. The collector will:
1. **Trace 1** (should NOT be sampled): Single span from `service.name="frontend"` but without the required span event
   - Has policy group match ✅
   - Has service.name="frontend" ✅
   - Missing span event named "example.event" ❌
   - Result: NOT sampled (all OTTL conditions must match)
2. **Trace 2** (should be sampled): Single span from `service.name="frontend"` WITH the required span event
   - Has policy group match ✅
   - Has service.name="frontend" ✅
   - Has span event named "example.event" ✅
   - Result: SAMPLED (all OTTL conditions match)
3. The OTTL condition policy requires BOTH conditions to be true:
   - Span resource attribute: `service.name == "frontend"`
   - Span event: name == "example.event"
4. This demonstrates how OTTL conditions can filter based on complex criteria including span events

### 7. Send spans demonstrating decision cache (requires `config-decision-cache.yaml`)

**Important**: This test requires using the `config-decision-cache.yaml` configuration file instead of the default `config.yaml`.

```bash
# Run the collector with the decision cache config
./00_run.sh config-decision-cache.yaml

# In another terminal, run the test script
./07_send-spans-decision-cache-example.sh
```

The `config-decision-cache.yaml` file is preconfigured with:
- `num_traces: 1` (forces trace eviction for testing)
- `decision_cache` enabled with cache sizes of 10000

This script demonstrates how the decision cache handles late-arriving spans. It sends spans in a specific sequence to show cache behavior:

1. **Span 1** (TRACE_ID_1, with ERROR): Sent immediately
   - Matches error-sampling policy group ✅
   - Has ERROR status ✅
   - Result: SAMPLED
   - Decision cached for TRACE_ID_1

2. **Wait 6 seconds** (longer than decision_wait of 5s): Decision is made and cached

3. **Span 2** (TRACE_ID_2, no error): Sent to evict TRACE_ID_1 from num_traces cache
   - With `num_traces: 1`, the collector can only hold 1 trace in memory
   - TRACE_ID_1 is evicted from the num_traces cache
   - But the sampling decision for TRACE_ID_1 remains in decision_cache

4. **Wait another 6 seconds**: Ensures TRACE_ID_2's decision is also made

5. **Span 3** (TRACE_ID_1 again, no error): Late-arriving span for TRACE_ID_1
   - TRACE_ID_1 is no longer in num_traces cache (evicted by TRACE_ID_2)
   - But TRACE_ID_1's "sampled" decision IS in decision_cache
   - Result: SAMPLED (using cached decision, even though it arrived late)

**Key Learning**: The decision cache allows the collector to handle late-arriving spans efficiently. Without the cache, late-arriving spans would require re-evaluating policies or might be dropped. With the cache, the collector remembers past sampling decisions and applies them to late-arriving spans.

### 8. Send spans with composite policy sampling (requires `config-composite.yaml`)

**Important**: This test requires using the `config-composite.yaml` configuration file instead of the default `config.yaml`.

```bash
# Run the collector with the composite config
./00_run.sh config-composite.yaml

# In another terminal, run the test script
./08_send-spans-composite-sampled.sh
```

Sends four separate traces to demonstrate rate allocation and rate limiting behavior. The test is designed to show what happens when a sub-policy exceeds its allocated rate limit.

**Test Scenario:**
- **Trace 1**: Error (status 500) → Sampled by policy-1 (within rate limit)
- **Trace 2**: Error (status 500) + POST → Sampled by policy-1 (matches both policies, but policy-1 is first in array)
- **Trace 3**: Error (status 503) → **Dropped** by policy-1 (exceeds 2 spans/s rate limit)
- **Trace 4**: POST only → Sampled by policy-2 (doesn't match policy-1, within policy-2's limit)

**How Composite Policy Evaluation Works:**

The composite policy evaluates sub-policies using **"first match wins"** logic. Sub-policies are evaluated **in the order they appear in the `composite_sub_policy` array**:

1. **For each trace**, sub-policies are evaluated in array order: policy-1, then policy-2
2. **First sub-policy that matches**:
   - If under its rate limit → **Sample and STOP** (trace is sampled)
   - If over its rate limit → **Drop and STOP** (trace is dropped, remaining policies are NOT checked)
3. **If no sub-policy matches** → Trace is NOT sampled

**Example: Trace with `http.status_code=500` AND `http.method=POST`**
- Matches BOTH policy-1 (errors) and policy-2 (mutations)
- Policy-1 is checked first (it's first in the `composite_sub_policy` array)
- Policy-1 matches → trace is allocated to policy-1's rate limit (2 spans/s)
- Policy-2 is never evaluated (first match wins)

**Rate Allocation Configuration:**
- **test-composite-policy-1** (errors, 50% = 2 spans/s): Highest priority (first in array)
- **test-composite-policy-2** (mutations, 50% = 2 spans/s): Second priority (second in array)
- **Total**: 4 spans/s (intentionally low for testing)

The collector will:
1. Collect all spans for the trace (waits up to 5s)
2. Evaluate trace globally (composite policy is not restricted to a policy group)
3. Check sub-policies in array order until one matches and makes a decision
4. Apply the matched policy's rate limit

**Key Points:**
- Unlike other policies, composite cannot be wrapped with an `and` policy to check for `policy.group` attributes
- Sub-policy evaluation stops at the first match (built-in short-circuit behavior)
- **Order matters**: Place higher-priority policies first in the `composite_sub_policy` array - earlier policies "steal" traces from later ones if they match
- **Rate limiting is strict**: Once a sub-policy exceeds its rate limit, matching traces are dropped (not passed to other policies)
- The `policy_order` field exists in the config but is not currently used by the implementation - evaluation order is determined by array position
- Rate limits are enforced per-second, so timing matters when running tests
