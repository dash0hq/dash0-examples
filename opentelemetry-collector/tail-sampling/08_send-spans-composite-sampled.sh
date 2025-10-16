#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Generate unique trace IDs - we'll send 4 traces to demonstrate rate limiting
TRACE_ID_1="$(date +%s)805a7c87bc2f6dab95a7f1"
TRACE_ID_2="$(date +%s)805a7c87bc2f6dab95a7f2"
TRACE_ID_3="$(date +%s)805a7c87bc2f6dab95a7f3"
TRACE_ID_4="$(date +%s)805a7c87bc2f6dab95a7f4"

echo "=========================================="
echo "Composite Policy Rate Allocation Test"
echo "=========================================="
echo ""
echo "IMPORTANT: This test requires a special config!"
echo "  Run the collector with: ./00_run.sh config-composite.yaml"
echo ""
echo "This test demonstrates rate allocation by sending traces that"
echo "exceed the rate limit of the first sub-policy, forcing later"
echo "traces to be evaluated by other sub-policies."
echo ""
echo "Configuration:"
echo "  - max_total_spans_per_second: 4"
echo "  - policy-1 (errors): 50% = 2 spans/s"
echo "  - policy-2 (mutations): 50% = 2 spans/s"
echo ""
echo "Test scenario:"
echo "  Trace 1: Error (http.status_code=500) → matches policy-1 ✓"
echo "  Trace 2: Error + Mutation → matches policy-1 FIRST (array order)"
echo "  Trace 3: Error → exceeds policy-1 rate limit, DROPPED ✗"
echo "  Trace 4: Mutation (http.method=POST) → matches policy-2 ✓"
echo ""
echo "If you haven't started the collector yet, open another terminal and run:"
echo "  ./00_run.sh config-composite.yaml"
echo ""
echo "Press Enter to continue with the test, or Ctrl+C to abort..."
read -r
echo ""

# Trace 1: Error trace - should be sampled by policy-1
echo "=========================================="
echo "Trace 1 (ID: ${TRACE_ID_1})"
echo "=========================================="
echo "Sending error trace (http.status_code=500)"
echo "  → Expected: SAMPLED by policy-1 (first error, within rate limit)"
echo ""
curl -s http://localhost:4318/v1/traces \
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
                  "key": "http.status_code",
                  "value": { "intValue": 500 }
                },
                {
                  "key": "http.method",
                  "value": { "stringValue": "GET" }
                }
              ],
              "startTimeUnixNano": "'$(date +%s%N)'",
              "endTimeUnixNano": "'$(date +%s%N)'",
              "events": [],
              "flags": 0,
              "kind": 1,
              "links": [],
              "name": "HTTP GET /api/data",
              "traceId": "'$TRACE_ID_1'",
              "parentSpanId": "",
              "spanId": "e22ea8f8e32c0e61",
              "traceState": "",
              "status": {
                "code": 2,
                "message": "Internal Server Error"
              }
            }
          ]
        }
      ]
    }
  ]
}' > /dev/null
echo "✓ Sent"

echo ""
echo "=========================================="
echo "Trace 2 (ID: ${TRACE_ID_2})"
echo "=========================================="
echo "Sending error + mutation trace (http.status_code=500, http.method=POST)"
echo "  → Expected: SAMPLED by policy-1 (matches BOTH policies, policy-1 first in array)"
echo ""
curl -s http://localhost:4318/v1/traces \
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
            "value": { "stringValue": "backend-api" }
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
                  "key": "http.status_code",
                  "value": { "intValue": 500 }
                },
                {
                  "key": "http.method",
                  "value": { "stringValue": "POST" }
                }
              ],
              "startTimeUnixNano": "'$(date +%s%N)'",
              "endTimeUnixNano": "'$(date +%s%N)'",
              "events": [],
              "flags": 0,
              "kind": 1,
              "links": [],
              "name": "HTTP POST /api/update",
              "traceId": "'$TRACE_ID_2'",
              "parentSpanId": "",
              "spanId": "e22ea8f8e32c0e62",
              "traceState": "",
              "status": {
                "code": 2,
                "message": "Internal Server Error"
              }
            }
          ]
        }
      ]
    }
  ]
}' > /dev/null
echo "✓ Sent"

echo ""
echo "=========================================="
echo "Trace 3 (ID: ${TRACE_ID_3})"
echo "=========================================="
echo "Sending error trace (http.status_code=500)"
echo "  → Expected: DROPPED by policy-1 (third error, exceeds 1 span/s rate limit)"
echo ""
curl -s http://localhost:4318/v1/traces \
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
            "value": { "stringValue": "backend-billing" }
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
                  "key": "http.status_code",
                  "value": { "intValue": 503 }
                },
                {
                  "key": "http.method",
                  "value": { "stringValue": "GET" }
                }
              ],
              "startTimeUnixNano": "'$(date +%s%N)'",
              "endTimeUnixNano": "'$(date +%s%N)'",
              "events": [],
              "flags": 0,
              "kind": 1,
              "links": [],
              "name": "HTTP GET /api/health",
              "traceId": "'$TRACE_ID_3'",
              "parentSpanId": "",
              "spanId": "e22ea8f8e32c0e63",
              "traceState": "",
              "status": {
                "code": 2,
                "message": "Service Unavailable"
              }
            }
          ]
        }
      ]
    }
  ]
}' > /dev/null
echo "✓ Sent"

echo ""
echo "=========================================="
echo "Trace 4 (ID: ${TRACE_ID_4})"
echo "=========================================="
echo "Sending mutation trace (http.method=POST, http.status_code=200)"
echo "  → Expected: SAMPLED by policy-2 (mutation, within rate limit)"
echo ""
curl -s http://localhost:4318/v1/traces \
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
            "value": { "stringValue": "backend-orders" }
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
                  "key": "http.status_code",
                  "value": { "intValue": 200 }
                },
                {
                  "key": "http.method",
                  "value": { "stringValue": "POST" }
                }
              ],
              "startTimeUnixNano": "'$(date +%s%N)'",
              "endTimeUnixNano": "'$(date +%s%N)'",
              "events": [],
              "flags": 0,
              "kind": 1,
              "links": [],
              "name": "HTTP POST /api/orders",
              "traceId": "'$TRACE_ID_4'",
              "parentSpanId": "",
              "spanId": "e22ea8f8e32c0e64",
              "traceState": "",
              "status": {
                "code": 1,
                "message": "OK"
              }
            }
          ]
        }
      ]
    }
  ]
}' > /dev/null
echo "✓ Sent"

echo ""
echo "=========================================="
echo "Test Complete - Waiting for decision..."
echo "=========================================="
echo ""
echo "Waiting 6 seconds for sampling decision (decision_wait=5s + buffer)..."
sleep 6

echo ""
echo "=========================================="
echo "Expected Results"
echo "=========================================="
echo ""
echo "Trace 1 (${TRACE_ID_1}): ✓ SAMPLED by policy-1"
echo "  - First error trace, within policy-1 rate limit (2 spans/s)"
echo ""
echo "Trace 2 (${TRACE_ID_2}): ✓ SAMPLED by policy-1"
echo "  - Matches BOTH policy-1 (error) and policy-2 (mutation)"
echo "  - Policy-1 evaluated first (array order)"
echo "  - Still within policy-1 rate limit"
echo ""
echo "Trace 3 (${TRACE_ID_3}): ✗ DROPPED by policy-1"
echo "  - Third error trace, EXCEEDS policy-1 rate limit (2 spans/s)"
echo "  - 'First match wins' - once policy-1 drops it, no other policy evaluates it"
echo ""
echo "Trace 4 (${TRACE_ID_4}): ✓ SAMPLED by policy-2"
echo "  - Mutation trace (POST)"
echo "  - Does NOT match policy-1 (no error)"
echo "  - Matches policy-2, within its rate limit (2 spans/s)"
echo ""
echo "Key Learning:"
echo "  1. Rate allocation prevents any sub-policy from exceeding its limit"
echo "  2. 'First match wins' means once a policy evaluates a trace (sample OR drop),"
echo "     no other policies are checked"
echo "  3. Array order matters - earlier policies 'steal' matching traces from later ones"
echo "  4. Rate limits are enforced per-second, so timing matters"
echo ""
echo "Rate Allocation (configured):"
echo "  - max_total_spans_per_second: 4"
echo "  - test-composite-policy-1 (errors): 50% = 2 spans/s"
echo "  - test-composite-policy-2 (mutations): 50% = 2 spans/s"