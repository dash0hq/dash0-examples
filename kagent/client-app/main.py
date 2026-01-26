"""
LangChain client application that interacts with kagent agents.
Demonstrates distributed tracing across LangChain → kagent → Anthropic.
"""
import os
import httpx
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

app = FastAPI(title="LangChain Kagent Client")

# Mount static files
app.mount("/static", StaticFiles(directory="/app/static"), name="static")

# Configuration
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514")
KAGENT_API_URL = os.getenv("KAGENT_API_URL", "http://kagent-controller.kagent.svc.cluster.local:8083")

# LangChain setup (used for observability/tracing)
# The ChatAnthropic client will automatically be instrumented by OpenTelemetry
llm = ChatAnthropic(
    api_key=ANTHROPIC_API_KEY,
    model=ANTHROPIC_MODEL,
    max_tokens=300
)


class QueryRequest(BaseModel):
    query: str


class QueryResponse(BaseModel):
    query: str
    response: str


@app.get("/")
async def root():
    return FileResponse("/app/static/index.html")


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.post("/query", response_model=QueryResponse)
async def query(request: QueryRequest):
    """
    Process a query through the kagent observability-agent.
    LangChain is used here for its OpenTelemetry instrumentation,
    creating distributed traces: LangChain client → kagent → Anthropic
    """
    try:
        # Send the query directly to the kagent observability-agent
        # The httpx client calls will be instrumented by OpenTelemetry
        response = await call_kagent_agent(
            agent_name="observability-agent",
            message=request.query
        )

        return QueryResponse(
            query=request.query,
            response=response
        )

    except Exception as e:
        import traceback
        error_detail = f"{str(e)}\n\nTraceback:\n{traceback.format_exc()}"
        print(f"Error processing query: {error_detail}", flush=True)
        raise HTTPException(status_code=500, detail=str(e))


async def call_kagent_agent(agent_name: str, message: str) -> str:
    """
    Call a kagent agent via the A2A API using JSON-RPC 2.0.
    This creates a distributed trace: Client app → kagent → LLM
    """
    import uuid

    # Use the A2A protocol endpoint
    url = f"{KAGENT_API_URL}/api/a2a/kagent/{agent_name}/"

    # A2A protocol uses JSON-RPC 2.0 format
    # contextId is required for agents with MCP tools
    payload = {
        "jsonrpc": "2.0",
        "method": "message/send",
        "params": {
            "message": {
                "role": "user",
                "parts": [
                    {
                        "kind": "text",
                        "text": message
                    }
                ]
            },
            "contextId": str(uuid.uuid4())
        },
        "id": 1
    }

    async with httpx.AsyncClient(timeout=300.0) as client:
        response = await client.post(url, json=payload)
        response.raise_for_status()

        result = response.json()

        # Extract the agent's response from the JSON-RPC result
        if "result" in result:
            result_data = result["result"]

            # Check for status message (primary response)
            if "status" in result_data and "message" in result_data["status"]:
                parts = result_data["status"]["message"].get("parts", [])
                if parts and len(parts) > 0:
                    return parts[0].get("text", str(result))

            # Extract from artifacts
            if "artifacts" in result_data and len(result_data["artifacts"]) > 0:
                artifact = result_data["artifacts"][0]
                if "parts" in artifact and len(artifact["parts"]) > 0:
                    return artifact["parts"][0].get("text", str(result))

        return str(result)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
