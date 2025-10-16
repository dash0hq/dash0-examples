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
                "message": "Healthy (Unset) span - not sampled"
              }
            },
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
              "traceId": "'$(date +%s)'705a7c87bc2f6dab94a7f4",
              "parentSpanId": "",
              "spanId": "e42ea8f8e32c0e78",
              "traceState": "",
              "status": {
                "code": 1,
                "message": "Healthy (OK) span - not sampled"
              }
            }
          ]
        }
      ]
    }
  ]
}'

echo -e "\nTwo spans sent with different trace IDs (UNSET and OK status codes)"
echo "These spans will NOT be sampled because:"
echo "  - They don't have a policy.group attribute, so no policy group will match them"
echo "  - Without a matching policy group, they will be dropped by the tail sampling processor"