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
            "value": { "stringValue": "ingestion-test" }
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
              "traceId": "'$(date +%s)'805a7c87bc2f6dab94a7f4",
              "parentSpanId": "",
              "spanId": "e42ea8f8e32c0e68",
              "traceState": "",
              "status": {
                "code": 0,
                "message": ""
              }
            }
          ]
        }
      ]
    }
  ]
}'