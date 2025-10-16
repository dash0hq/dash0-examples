#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Single trace ID to be shared across all spans
TRACE_ID="$(date +%s)805a7c87bc2f6dab95a7f2"

echo "=========================================="
echo "Composite Policy Test"
echo "=========================================="
echo ""
echo "Sending trace with ID: ${TRACE_ID}"
echo ""
echo "This test demonstrates composite policy 'first match wins' behavior:"
echo "  - Sub-policies are evaluated in order: policy-1 → policy-2 → policy-3"
echo "  - First matching sub-policy claims the trace"
echo "  - Remaining sub-policies are NOT evaluated after first match"
echo ""
echo "IMPORTANT: This test requires running collector with config-composite.yaml"
echo "  Run: ./08_run_composite.sh"
echo ""

# Span 1: High status code (>= 400) - should be allocated to test-composite-policy-1 (50% rate)
echo "Step 1: Sending Span 1 (http.status_code=500, http.method=GET)"
echo "  - Matches test-composite-policy-1 (http.status_code >= 400) ✅"
echo "  - Also would match test-composite-policy-3 (always_sample) ✅"
echo "  - But policy-1 is evaluated FIRST in policy_order"
echo ""
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
                },
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
              "traceId": "'$TRACE_ID'",
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
}'

# Simulate minimum latency
sleep .1

# Span 2: Mutating HTTP method (POST) - should be allocated to test-composite-policy-2 (25% rate)
echo "Step 2: Sending Span 2 (http.status_code=200, http.method=POST)"
echo "  - Does NOT match test-composite-policy-1 (status < 400) ❌"
echo "  - Matches test-composite-policy-2 (http.method=POST) ✅"
echo "  - Also would match test-composite-policy-3 (always_sample) ✅"
echo "  - But policy-2 is evaluated BEFORE policy-3"
echo ""
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
                  "key": "endpoint.name",
                  "value": { "stringValue": "OTLP via HTTP" }
                },
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
              "name": "HTTP POST /api/charge",
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "e22ea8f8e32c0e61",
              "spanId": "e22ea8f8e32c0e62",
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
}'

# Simulate minimum latency
sleep .2

# Span 3: Regular span - should be allocated to test-composite-policy-3 (remaining capacity)
echo "Step 3: Sending Span 3 (http.status_code=200, http.method=GET)"
echo "  - Does NOT match test-composite-policy-1 (status < 400) ❌"
echo "  - Does NOT match test-composite-policy-2 (method not in [POST,PUT,DELETE]) ❌"
echo "  - Matches test-composite-policy-3 (always_sample) ✅"
echo "  - Policy-3 is the ONLY match"
echo ""
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
                  "key": "endpoint.name",
                  "value": { "stringValue": "OTLP via HTTP" }
                },
                {
                  "key": "http.status_code",
                  "value": { "intValue": 200 }
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
              "name": "HTTP GET /api/status",
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "e22ea8f8e32c0e62",
              "spanId": "e22ea8f8e32c0e63",
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
}'

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
echo ""
echo "Summary of trace ${TRACE_ID}:"
echo ""
echo "Composite policy evaluates the ENTIRE TRACE (not individual spans):"
echo "  - Because Span 1 has http.status_code=500"
echo "  - The ENTIRE TRACE matches test-composite-policy-1 FIRST"
echo "  - Result: Trace allocated to policy-1's rate limit (500 spans/s)"
echo "  - Policies 2 and 3 are NEVER evaluated (first match wins)"
echo ""
echo "Key Learning:"
echo "  - Composite policy uses 'first match wins' logic"
echo "  - If a trace matches policy-1, it's allocated to policy-1's rate"
echo "  - Even though Span 2 has method=POST, policy-2 is never checked"
echo "  - Policy order in policy_order determines priority"
echo ""
echo "Rate Allocation (at scale):"
echo "  - test-composite-policy-1 (errors): 50% = 500 spans/s"
echo "  - test-composite-policy-2 (mutations): 25% = 250 spans/s"
echo "  - test-composite-policy-3 (always_sample): 25% = 250 spans/s"
echo "  - Total: 1000 spans/s"
echo ""
echo "To observe rate limiting behavior, send many traces under load."
