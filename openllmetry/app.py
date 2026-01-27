"""
OpenLLMetry demo with nested traces and custom spans.
Shows customer support workflow with sentiment analysis.
"""

import os
import time
from dotenv import load_dotenv
from anthropic import Anthropic
from traceloop.sdk import Traceloop
from opentelemetry import trace
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

load_dotenv()

tracer = trace.get_tracer(__name__)


def initialize_observability():
    """Initialize OpenLLMetry with HTTP instrumentation."""
    Traceloop.init(
        app_name="openllmetry-demo",
        disable_batch=True,
        api_endpoint="http://localhost:4318",
        resource_attributes={
            "service.version": "1.0.0",
            "deployment.environment": "demo",
        }
    )
    HTTPXClientInstrumentor().instrument()
    print("OpenLLMetry initialized")


def analyze_sentiment(client: Anthropic, text: str) -> str:
    """Analyze sentiment of text using Claude."""
    with tracer.start_as_current_span("analyze_sentiment") as span:
        span.set_attribute("input.text_length", len(text))

        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=50,
            messages=[
                {
                    "role": "user",
                    "content": f"Analyze the sentiment of this text in one word (positive/negative/neutral): {text}"
                }
            ]
        )

        sentiment = response.content[0].text.strip().lower()
        span.set_attribute("output.sentiment", sentiment)
        return sentiment


def generate_response(client: Anthropic, user_query: str, sentiment: str) -> str:
    """Generate a response based on user query and sentiment."""
    with tracer.start_as_current_span("generate_response") as span:
        span.set_attribute("input.query", user_query)
        span.set_attribute("input.sentiment", sentiment)

        system_prompt = f"You are a helpful assistant. The user's message has {sentiment} sentiment. Respond accordingly."

        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=200,
            messages=[
                {
                    "role": "user",
                    "content": user_query
                }
            ],
            system=system_prompt
        )

        result = response.content[0].text
        span.set_attribute("output.tokens_used", response.usage.output_tokens)
        return result


def process_customer_query(query: str):
    """Process customer query with sentiment analysis."""
    with tracer.start_as_current_span("process_customer_query") as parent_span:
        parent_span.set_attribute("customer.query", query)
        parent_span.set_attribute("workflow.type", "customer_support")

        print(f"\nProcessing: {query}")

        client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

        # Analyze sentiment
        sentiment = analyze_sentiment(client, query)
        print(f"Sentiment: {sentiment}")

        # Simulate validation
        with tracer.start_as_current_span("validate_query") as span:
            span.set_attribute("validation.type", "content_safety")
            time.sleep(0.5)

        # Generate response
        response = generate_response(client, query, sentiment)
        print(f"Response: {response}\n")

        parent_span.set_attribute("workflow.status", "completed")


def main():
    """Main execution function."""
    if not os.getenv("ANTHROPIC_API_KEY"):
        print("ERROR: ANTHROPIC_API_KEY not found")
        return

    print("OpenLLMetry Demo - Customer Support Workflow")
    initialize_observability()

    # Process queries
    process_customer_query("I'm having trouble connecting to the API. Can you help?")
    process_customer_query("This service is amazing! I love how easy it is to use.")

    print("Demo complete - check Dash0 for traces")


if __name__ == "__main__":
    main()
