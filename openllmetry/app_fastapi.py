"""
FastAPI app with OpenLLMetry auto-instrumentation.
All HTTP and LLM calls are automatically traced.
"""

import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="OpenLLMetry FastAPI Demo")

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")


class QueryRequest(BaseModel):
    query: str
    max_tokens: int = 200


class QueryResponse(BaseModel):
    query: str
    response: str
    sentiment: str
    tokens_used: int


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/analyze", response_model=QueryResponse)
async def analyze_query(request: QueryRequest):
    """Analyze query with sentiment detection and response generation."""
    if not ANTHROPIC_API_KEY:
        raise HTTPException(status_code=500, detail="ANTHROPIC_API_KEY not configured")

    client = Anthropic(api_key=ANTHROPIC_API_KEY)

    # Analyze sentiment
    sentiment_response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=10,
        messages=[
            {
                "role": "user",
                "content": f"Analyze sentiment in one word: {request.query}"
            }
        ]
    )
    sentiment = sentiment_response.content[0].text.strip().lower()

    # Generate response
    main_response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=request.max_tokens,
        messages=[
            {
                "role": "user",
                "content": request.query
            }
        ]
    )

    return QueryResponse(
        query=request.query,
        response=main_response.content[0].text,
        sentiment=sentiment,
        tokens_used=(
            sentiment_response.usage.input_tokens +
            sentiment_response.usage.output_tokens +
            main_response.usage.input_tokens +
            main_response.usage.output_tokens
        )
    )


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "service": "OpenLLMetry FastAPI Demo",
        "endpoints": {
            "health": "/health",
            "analyze": "/analyze (POST)",
            "docs": "/docs"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
