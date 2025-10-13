#!/usr/bin/env bash

set -eo pipefail

source ../../.env

curl http://localhost:4318/v1/logs \
  -X POST \
  -H "Content-Type: application/json" \
  -d '
{
  "resourceLogs": [
    {
      "resource": {
        "attributes": [
          {
            "key": "service.name",
            "value": {
              "stringValue": "ingest-test"
            }
          }
        ]
      },
      "scopeLogs": [
        {
          "logRecords": [
            {
              "attributes": [],
              "body": {
                "stringValue": "Hello World!"
              },
              "droppedAttributesCount": 0,
              "flags": 0,
              "severityNumber": 9,
              "severityText": "",
              "spanId": "",
              "traceId": ""
            }
          ]
        }
      ]
    }
  ],
  "resourceSpans": []
}'