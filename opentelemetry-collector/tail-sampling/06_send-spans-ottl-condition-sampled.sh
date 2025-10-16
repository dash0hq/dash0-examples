#!/usr/bin/env bash

set -eo pipefail

source ../../.env

# Generate unique trace IDs
TRACE_ID_1="$(date +%s)805a7c87bc2f6dab94a7f1"
TRACE_ID_2="$(date +%s)805a7c87bc2f6dab94a7f2"

echo "Sending OTTL condition sampling test spans..."
echo ""
echo "Trace 1 (traceId: ${TRACE_ID_1}):"
echo "  - service.name='frontend' ✅"
echo "  - policy.group='ottl-condition-sampling' ✅"
echo "  - Span event 'example.event' ❌ (MISSING)"
echo "  Expected: NOT SAMPLED (OTTL conditions require BOTH service.name AND span event)"
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
          },
          {
            "key": "policy.group",
            "value": { "stringValue": "ottl-condition-sampling" }
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

# Simulate minimal latency
sleep .1

echo "Trace 2 (traceId: ${TRACE_ID_2}):"
echo "  - service.name='frontend' ✅"
echo "  - policy.group='ottl-condition-sampling' ✅"
echo "  - Span event 'example.event' ✅ (PRESENT)"
echo "  Expected: SAMPLED (all OTTL conditions match)"
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
          },
          {
            "key": "policy.group",
            "value": { "stringValue": "ottl-condition-sampling" }
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
              "events": [
                {
                  "timeUnixNano": "'$(date +%s%N)'",
                  "name": "example.event",
                  "attributes": [
                    {
                      "key": "example.attribute",
                      "value": { "stringValue": "example.value" }
                    }
                  ]
                }
              ],
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

echo ""
echo "Summary:"
echo "  - Trace 1 (${TRACE_ID_1}): Should NOT be sampled (missing span event)"
echo "  - Trace 2 (${TRACE_ID_2}): Should be sampled (has all required conditions)"
echo ""
echo "The OTTL condition policy demonstrates advanced filtering using:"
echo "  1. Resource attributes (service.name)"
echo "  2. Span events (event with name 'example.event')"
echo "  Both conditions must match for the trace to be sampled."
