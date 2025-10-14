#!/usr/bin/env bash

set -eo pipefail

source ../../.env

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
              "traceId": "'$(date +%s)805a7c87bc2f6dab94a7f1'",
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
              "traceId": "'$(date +%s)805a7c87bc2f6dab94a7f2'",
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
