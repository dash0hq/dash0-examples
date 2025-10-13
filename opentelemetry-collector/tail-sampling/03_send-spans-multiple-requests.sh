#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Generate a single trace ID to be shared across all spans
TRACE_ID="$(date +%s)805a7c87bc2f6dab94a7f4"

echo "Sending 3 spans with trace ID: $TRACE_ID"
echo ""

# Send first span
echo "Sending span 1/3..."
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
            "value": { "stringValue": "tail-sampling-ingestion-test" }
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
              "name": "Manually Ingested Span - drop me",
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "",
              "spanId": "e42ea8f8e32c0e61",
              "traceState": "",
              "status": {
                "code": 0,
                "message": "First span in trace"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo ""
echo "Span 1/3 sent successfully"
echo ""

# Wait 1 second before sending next span
sleep 1

# Send second span
echo "Sending span 2/3..."
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
            "value": { "stringValue": "tail-sampling-ingestion-test" }
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
              "name": "Manually Ingested Span - drop me",
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "",
              "spanId": "e42ea8f8e32c0e62",
              "traceState": "",
              "status": {
                "code": 0,
                "message": "Second span in trace"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo ""
echo "Span 2/3 sent successfully"
echo ""

# Wait 1 second before sending next span
sleep 1

# Send third span
echo "Sending span 3/3..."
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
            "value": { "stringValue": "tail-sampling-ingestion-test" }
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
              "name": "Manually Ingested Span - do NOT drop me",
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "",
              "spanId": "e42ea8f8e32c0e63",
              "traceState": "",
              "status": {
                "code": 2,
                "message": "Third span in trace - error status"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo ""
echo "Span 3/3 sent successfully"
echo ""
echo "All 3 spans sent with trace ID: $TRACE_ID"
