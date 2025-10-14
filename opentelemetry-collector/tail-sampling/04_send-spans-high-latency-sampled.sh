#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Single trace ID to be shared across all spans
TRACE_ID="$(date +%s)805a7c87bc2f6dab95a7f4"

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
            "value": { "stringValue": "latency-sampling" }
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
              "spanId": "e32ea8f8e32c0e61",
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

# Simulate high latency
sleep 1

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
            "value": { "stringValue": "latency-sampling" }
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
              "parentSpanId": "e32ea8f8e32c0e61",
              "spanId": "e32ea8f8e32c0e62",
              "traceState": "",
              "status": {
                "code": 1,
                "message": "Billing - high latency"
              }
            }
          ]
        }
      ]
    }
  ]
}'

# Simulate high latency
sleep 1

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
            "value": { "stringValue": "latency-sampling" }
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
              "name": "Manually Ingested Span - high latency sampled",
              "traceId": "'$TRACE_ID'",
              "parentSpanId": "e32ea8f8e32c0e62",
              "spanId": "e32ea8f8e32c0e63",
              "traceState": "",
              "status": {
                "code": 1,
                "message": "Backend API - high latency"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo -e "\nHigh latency spans sent with traceId: ${TRACE_ID}"
echo "This trace WILL be sampled because:"
echo "  - policy.group='latency-sampling' matches the slow-traces-policy group"
echo "  - The trace has latency > 1000ms (due to 5+ second delay between spans)"
echo "  - The entire trace will be sampled and exported to Dash0"