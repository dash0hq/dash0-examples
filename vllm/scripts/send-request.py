#!/usr/bin/env python3
"""Send sample queries to the RAG app to generate traces and metrics."""

import json
import sys
import urllib.error
import urllib.request

RAG_URL = "http://localhost:8001/query"

QUERIES = [
    "What is OpenTelemetry?",
    "How does vLLM work?",
    "Explain distributed tracing",
    "What is Prometheus used for?",
    "Tell me about Dash0",
]


def send_query(query: str) -> dict:
    payload = json.dumps({"query": query}).encode()
    req = urllib.request.Request(
        RAG_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read())


def main():
    print(f"Sending {len(QUERIES)} queries to {RAG_URL}\n")
    errors = 0

    for query in QUERIES:
        print(f"Query:   {query}")
        try:
            result = send_query(query)
            print(f"Context: {result['context'][:80]}...")
            print(f"Answer:  {result['answer'][:120]}")
        except urllib.error.URLError as e:
            print(f"Error:   {e}")
            errors += 1
        print()

    if errors:
        print(f"{errors} request(s) failed — is the RAG app running? (docker compose up)")
        sys.exit(1)

    print("Done. Check Dash0 for traces and metrics.")


if __name__ == "__main__":
    main()
