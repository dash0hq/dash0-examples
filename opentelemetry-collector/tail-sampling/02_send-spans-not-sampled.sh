#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Single trace ID to be shared across all spans
TRACE_ID="$(date +%s)805a7c87bc2f6dab94a7f1"

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
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "",
              "spanId": "e12ea8f8e32c0e61",
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
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "",
              "spanId": "e12ea8f8e32c0e62",
              "traceState": "",
              "status": {
                "code": 1,
                "message": "Billing - OK"
              }
            }
          ]
        }
      ]
    }
  ]
}'

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
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "",
              "spanId": "e12ea8f8e32c0e63",
              "traceState": "",
              "status": {
                "code": 1,
                "message": "Backend API - OK"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo -e "\nThree spans sent with shared traceId: ${TRACE_ID}"
echo "This trace will NOT be sampled because:"
echo "  - policy.group='error-sampling' matches the error-traces-policy group"
echo "  - BUT all spans have OK/UNSET status (no ERROR status code)"
echo "  - The error-traces-policy requires BOTH conditions, so the trace is dropped"
echo "  - Demonstrates policy evaluation where the policy group matches but sampling condition doesn't"
