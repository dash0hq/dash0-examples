#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Single trace ID to be shared across all spans
TRACE_ID_1="$(date +%s)805a7c87bc2f6dab95a7f1"
TRACE_ID_2="$(date +%s)805a7c87bc2f6dab95a7f2"

echo "=========================================="
echo "Decision Cache Test"
echo "=========================================="
echo ""
echo "IMPORTANT: This test requires a special config!"
echo "  Run the collector with: ./00_run.sh config-decision-cache.yaml"
echo ""
echo "This config sets num_traces=1 and enables decision_cache to demonstrate"
echo "how the cache handles late-arriving spans after trace eviction."
echo ""
echo "If you haven't started the collector yet, open another terminal and run:"
echo "  ./00_run.sh config-decision-cache.yaml"
echo ""
echo "Press Enter to continue with the test, or Ctrl+C to abort..."
read -r
echo ""
echo "Step 1: Sending Span 1 (TRACE_ID_1=${TRACE_ID_1}) with ERROR status"
echo "  - Will be SAMPLED due to error-sampling policy"
echo "  - Decision will be cached"
echo ""

# Send 1st span which should be sampled
curl http://localhost:4318/v1/traces \
  -X POST \
  -H "Content-Type: application/json" \
  -d '
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          {
            "key": "service.name",
            "value": { "stringValue": "frontend" }
          },
          {
            "key": "policy.group",
            "value": { "stringValue": "error-sampling" }
          }
        ]
      },
      "scopeSpans": [
        {
          "schemaUrl": "",
          "scope": {
            "attributes": []
          },
          "spans": [
            {
              "attributes": [
                {
                  "key": "endpoint.name",
                  "value": { "stringValue": "OTLP via HTTP" }
                }
              ],
              "startTimeUnixNano": "'$(date +%s%N)'",
              "endTimeUnixNano": "'$(date +%s%N)'",
              "events": [],
              "flags": 0,
              "kind": 1,
              "links": [],
              "name": "Manually Ingested Span",
              "traceId": "'$TRACE_ID_1'",
              "parentSpanId": "",
              "spanId": "e12ea8f8e32c0e61",
              "traceState": "",
              "status": {
                "code": 2,
                "message": "Frontend - ERROR"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo "Step 2: Waiting 6 seconds (longer than decision_wait=5s)"
echo "  - Collector makes sampling decision: SAMPLED"
echo "  - Decision is stored in decision_cache"
echo ""
sleep 6

echo "Step 3: Sending Span 2 (TRACE_ID_2=${TRACE_ID_2}) with no error"
echo "  - With num_traces=1, this will evict TRACE_ID_1 from memory"
echo "  - But TRACE_ID_1's decision remains in decision_cache"
echo "  - This span will NOT be sampled (no error)"
echo ""

# Send a span with different trace ID to evict the first one from the num_traces cache
# This one should not get sampled
curl http://localhost:4318/v1/traces \
  -X POST \
  -H "Content-Type: application/json" \
  -d '
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          {
            "key": "service.name",
            "value": { "stringValue": "frontend" }
          },
          {
            "key": "policy.group",
            "value": { "stringValue": "error-sampling" }
          }
        ]
      },
      "scopeSpans": [
        {
          "schemaUrl": "",
          "scope": {
            "attributes": []
          },
          "spans": [
            {
              "attributes": [
                {
                  "key": "endpoint.name",
                  "value": { "stringValue": "OTLP via HTTP" }
                }
              ],
              "startTimeUnixNano": "'$(date +%s%N)'",
              "endTimeUnixNano": "'$(date +%s%N)'",
              "events": [],
              "flags": 0,
              "kind": 1,
              "links": [],
              "name": "Manually Ingested Span",
              "traceId": "'$TRACE_ID_2'",
              "parentSpanId": "",
              "spanId": "e12ea8f8e32c0e62",
              "traceState": "",
              "status": {
                "code": 0,
                "message": "Frontend - UNSET"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo "Step 4: Waiting another 6 seconds"
echo "  - Allows TRACE_ID_2 decision to be made"
echo ""
# Wait more than we specified via decision_wait parameter
sleep 6

echo "Step 5: Sending Span 3 (TRACE_ID_1=${TRACE_ID_1} again) - LATE-ARRIVING SPAN"
echo "  - This span arrives late for TRACE_ID_1"
echo "  - TRACE_ID_1 is no longer in num_traces cache (was evicted)"
echo "  - But TRACE_ID_1's 'sampled' decision IS in decision_cache"
echo "  - Result: Will be SAMPLED using the cached decision!"
echo ""

# Send a 3rd span with the same trace ID as the 1st
# This one shouldn't be sampled by default,
# but will be sampled because we configured sampled_cache_size
curl http://localhost:4318/v1/traces \
  -X POST \
  -H "Content-Type: application/json" \
  -d '
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          {
            "key": "service.name",
            "value": { "stringValue": "frontend" }
          }
        ]
      },
      "scopeSpans": [
        {
          "schemaUrl": "",
          "scope": {
            "attributes": []
          },
          "spans": [
            {
              "attributes": [
                {
                  "key": "endpoint.name",
                  "value": { "stringValue": "OTLP via HTTP" }
                }
              ],
              "startTimeUnixNano": "'$(date +%s%N)'",
              "endTimeUnixNano": "'$(date +%s%N)'",
              "events": [],
              "flags": 0,
              "kind": 1,
              "links": [],
              "name": "Manually Ingested Span",
              "traceId": "'$TRACE_ID_1'",
              "parentSpanId": "",
              "spanId": "e12ea8f8e32c0e63",
              "traceState": "",
              "status": {
                "code": 0,
                "message": "Frontend - UNSET"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - TRACE_ID_1 (${TRACE_ID_1}):"
echo "      Span 1: SAMPLED (had error)"
echo "      Span 3 (late): SAMPLED (using cached decision)"
echo "  - TRACE_ID_2 (${TRACE_ID_2}):"
echo "      Span 2: NOT SAMPLED (no error)"
echo ""
echo "Key Takeaway:"
echo "  Decision cache allows late-arriving spans to use cached sampling decisions"
echo "  even after the trace has been evicted from the num_traces memory cache."
