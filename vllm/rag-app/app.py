import os

import httpx
from fastapi import FastAPI, HTTPException
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.propagate import inject
from prometheus_client import Counter, Histogram, make_asgi_app
from pydantic import BaseModel

# OTel auto-configures from OTEL_SERVICE_NAME and OTEL_EXPORTER_OTLP_ENDPOINT env vars
tracer = trace.get_tracer("rag-app")

# --- Prometheus metrics ---
RAG_REQUESTS = Counter("rag_queries_total", "Total number of RAG queries received")
RAG_LATENCY = Histogram("rag_query_duration_seconds", "End-to-end RAG query duration in seconds")

# --- App ---
app = FastAPI(title="RAG Demo App")
FastAPIInstrumentor.instrument_app(app, excluded_urls="/metrics,/health")
app.mount("/metrics", make_asgi_app())

VLLM_BASE_URL = os.getenv("VLLM_BASE_URL", "http://vllm:8000")
MODEL = "facebook/opt-125m"

DOCS = [
    "OpenTelemetry is a vendor-neutral observability framework for instrumenting, generating, collecting, and exporting telemetry data such as traces, metrics, and logs.",
    "vLLM is a high-throughput and memory-efficient inference and serving engine for large language models, supporting continuous batching and PagedAttention.",
    "Distributed tracing tracks requests as they flow across multiple services, providing end-to-end visibility and helping you understand latency and failures.",
    "Prometheus is an open-source systems monitoring and alerting toolkit that scrapes metrics from instrumented targets at given intervals.",
    "Dash0 is an OpenTelemetry-native observability platform that stores traces, metrics, and logs without proprietary agents or lock-in.",
]


class QueryRequest(BaseModel):
    query: str


def retrieve(query: str) -> str:
    query_lower = query.lower()
    for doc in DOCS:
        if any(word in doc.lower() for word in query_lower.split() if len(word) > 3):
            return doc
    return DOCS[0]


@app.post("/query")
async def query_endpoint(body: QueryRequest):
    RAG_REQUESTS.inc()

    with RAG_LATENCY.time():
        with tracer.start_as_current_span(
            "rag.query",
            attributes={
                "gen_ai.request.model": MODEL,
            },
        ) as span:
            with tracer.start_as_current_span("rag.retrieve") as retrieve_span:
                context = retrieve(body.query)
                retrieve_span.set_attribute("rag.context.length", len(context))

            with tracer.start_as_current_span("rag.generate") as gen_span:
                # Inject W3C trace context so vLLM spans are linked to this trace
                headers = {"Content-Type": "application/json"}
                inject(headers)

                prompt = f"Context: {context}\n\nQuestion: {body.query}\nAnswer:"
                gen_span.set_attribute("gen_ai.request.max_tokens", 100)

                try:
                    async with httpx.AsyncClient(timeout=120.0) as client:
                        resp = await client.post(
                            f"{VLLM_BASE_URL}/v1/completions",
                            json={
                                "model": MODEL,
                                "prompt": prompt,
                                "max_tokens": 100,
                                "temperature": 0.1,
                            },
                            headers=headers,
                        )
                        resp.raise_for_status()
                        result = resp.json()
                except httpx.HTTPError as e:
                    span.set_attribute("error.type", type(e).__name__)
                    raise HTTPException(status_code=503, detail=f"vLLM unavailable: {e}")

                choice = result["choices"][0]
                answer = choice["text"].strip()

                if "usage" in result:
                    span.set_attribute("gen_ai.usage.prompt_tokens", result["usage"].get("prompt_tokens", 0))
                    span.set_attribute("gen_ai.usage.completion_tokens", result["usage"].get("completion_tokens", 0))

    return {"query": body.query, "context": context, "answer": answer}


@app.get("/health")
def health():
    return {"status": "ok"}
