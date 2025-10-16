#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Generate unique trace IDs for each trace
TRACE_ID_1="$(date +%s)805a7c87bc2f6dab95a7f1"
TRACE_ID_2="$(date +%s)805a7c87bc2f6dab95a7f2"
TRACE_ID_3="$(date +%s)805a7c87bc2f6dab95a7f3"

echo "=========================================="
echo "Composite Policy Test"
echo "=========================================="
echo ""
echo "IMPORTANT: This test requires a special config!"
echo "  Run the collector with: ./00_run.sh config-composite.yaml"
echo ""
echo "This test demonstrates composite policy 'first match wins' behavior"
echo "by sending 3 SEPARATE traces that match different sub-policies:"
echo "  - Trace 1: Error (http.status_code >= 400) → policy-1"
echo "  - Trace 2: Mutation (http.method=POST) → policy-2"
echo "  - Trace 3: Regular request → policy-3"
echo ""
echo "If you haven't started the collector yet, open another terminal and run:"
echo "  ./00_run.sh config-composite.yaml"
echo ""
echo "Press Enter to continue with the test, or Ctrl+C to abort..."
read -r
echo ""

# Trace 1: Error trace - should be allocated to test-composite-policy-1 (50% rate)
echo "=========================================="
echo "Trace 1 (ID: ${TRACE_ID_1})"
echo "=========================================="
echo "Sending trace with error status (http.status_code=500)"
echo "  → Should match policy-1 (errors) FIRST"
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
}'

echo ""
echo "=========================================="
echo "Trace 2 (ID: ${TRACE_ID_2})"
echo "=========================================="
echo "Sending trace with mutation (http.method=POST, http.status_code=200)"
echo "  → Should match policy-2 (mutations) FIRST"
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
              "traceId": "'$TRACE_ID_2'",
              "parentSpanId": "",
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

echo ""
echo "=========================================="
echo "Trace 3 (ID: ${TRACE_ID_3})"
echo "=========================================="
echo "Sending regular trace (http.method=GET, http.status_code=200)"
echo "  → Should match policy-3 (always_sample)"
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
              "traceId": "'$TRACE_ID_3'",
              "parentSpanId": "",
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
echo "Test Complete - Waiting for decision..."
echo "=========================================="
echo ""
echo "Waiting 6 seconds for sampling decision (decision_wait=5s + buffer)..."
sleep 6

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "This test sent 3 separate traces to demonstrate composite policy behavior:"
echo ""
echo "Trace 1 (${TRACE_ID_1}):"
echo "  Service: frontend"
echo "  Attributes: http.status_code=500, http.method=GET"
echo "  → Should match policy-1 (errors) FIRST due to status code >= 400"
echo ""
echo "Trace 2 (${TRACE_ID_2}):"
echo "  Service: backend-billing"
echo "  Attributes: http.status_code=200, http.method=POST"
echo "  → Should match policy-2 (mutations) FIRST due to POST method"
echo ""
echo "Trace 3 (${TRACE_ID_3}):"
echo "  Service: backend-api"
echo "  Attributes: http.status_code=200, http.method=GET"
echo "  → Should match policy-3 (always_sample) as fallback"
echo ""
echo "Key Learning:"
echo "  - Composite policy evaluates sub-policies in array order (policy-1, policy-2, policy-3)"
echo "  - 'First match wins' - evaluation stops at the first sub-policy that matches"
echo "  - Each trace is evaluated independently"
echo "  - Rate allocation (50%/25%/25%) ensures each sub-policy gets its guaranteed share"
echo ""
echo "Rate Allocation (configured):"
echo "  - test-composite-policy-1 (errors): 50% = 500 spans/s"
echo "  - test-composite-policy-2 (mutations): 25% = 250 spans/s"
echo "  - test-composite-policy-3 (always_sample): 25% = 250 spans/s"
echo "  - Total: 1000 spans/s"
echo ""
echo "To verify the traces were sampled and exported, check the collector logs:"
echo "  docker logs \$(docker ps --filter 'publish=4317' --format '{{.ID}}') 2>&1 | grep -A 5 'tailsampling.composite_policy'"
