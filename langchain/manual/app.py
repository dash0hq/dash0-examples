"""
Simple LangChain app with Anthropic API and OpenTelemetry instrumentation.
This demonstrates what observability signals we get out of the box.
"""

import os
from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# Import OpenTelemetry components
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.semconv.resource import ResourceAttributes

# Import LangChain OpenTelemetry instrumentation
from opentelemetry.instrumentation.langchain import LangchainInstrumentor

# Load environment variables
load_dotenv()

def setup_telemetry():
    """Set up OpenTelemetry with OTLP export to local collector."""

    # Create resource with service information
    resource = Resource(attributes={
        ResourceAttributes.SERVICE_NAME: "langchain-anthropic-demo",
        ResourceAttributes.SERVICE_VERSION: "1.0.0",
        ResourceAttributes.DEPLOYMENT_ENVIRONMENT: "local",
    })

    # Create tracer provider
    provider = TracerProvider(resource=resource)

    # Configure OTLP exporter
    otlp_exporter = OTLPSpanExporter(
        endpoint="http://localhost:4317",
        insecure=True,
    )

    # Add span processor
    provider.add_span_processor(BatchSpanProcessor(otlp_exporter))

    # Set as global default
    trace.set_tracer_provider(provider)

    # Instrument LangChain
    LangchainInstrumentor().instrument()

    print("✓ OpenTelemetry configured and LangChain instrumented")


def simple_chat_example():
    """Simple chat example with Anthropic."""

    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span("simple_chat_example"):
        print("\n=== Simple Chat Example ===")

        # Initialize the Anthropic chat model
        llm = ChatAnthropic(
            model="claude-sonnet-4-20250514",
            temperature=0.7,
            max_tokens=1024,
        )

        # Simple invocation
        messages = [
            SystemMessage(content="You are a helpful AI assistant."),
            HumanMessage(content="Explain what observability means in the context of LLM applications in 2 sentences."),
        ]

        print("Sending request to Anthropic...")
        response = llm.invoke(messages)

        print(f"\nResponse: {response.content}")
        print(f"Model: {response.response_metadata.get('model', 'N/A')}")
        print(f"Tokens - Input: {response.usage_metadata.get('input_tokens', 'N/A')}, Output: {response.usage_metadata.get('output_tokens', 'N/A')}")


def chain_example():
    """Example using LangChain's chain composition."""

    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span("chain_example"):
        print("\n=== Chain Example ===")

        # Create a simple chain
        llm = ChatAnthropic(
            model="claude-sonnet-4-20250514",
            temperature=0.7,
            max_tokens=1024,
        )

        prompt = ChatPromptTemplate.from_messages([
            ("system", "You are an expert on {topic}."),
            ("human", "{question}"),
        ])

        output_parser = StrOutputParser()

        # Compose the chain
        chain = prompt | llm | output_parser

        print("Executing chain...")
        result = chain.invoke({
            "topic": "OpenTelemetry",
            "question": "What are the three main signal types in OpenTelemetry?"
        })

        print(f"\nChain result: {result}")


def streaming_example():
    """Example with streaming responses."""

    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span("streaming_example"):
        print("\n=== Streaming Example ===")

        llm = ChatAnthropic(
            model="claude-sonnet-4-20250514",
            temperature=0.7,
            max_tokens=512,
        )

        messages = [
            SystemMessage(content="You are a helpful assistant."),
            HumanMessage(content="Count from 1 to 5, with a brief explanation of each number's significance in computer science."),
        ]

        print("Streaming response:")
        for chunk in llm.stream(messages):
            print(chunk.content, end="", flush=True)

        print("\n")


def main():
    """Main execution function."""

    # Check for API key
    if not os.getenv("ANTHROPIC_API_KEY"):
        print("ERROR: ANTHROPIC_API_KEY not found in environment variables.")
        print("Please create a .env file with your API key.")
        return

    print("Starting LangChain + Anthropic + OpenTelemetry Demo")
    print("=" * 60)

    # Set up telemetry
    setup_telemetry()

    # Get main tracer
    tracer = trace.get_tracer(__name__)

    # Run examples within a root span
    with tracer.start_as_current_span("langchain_demo_app") as span:
        span.set_attribute("demo.type", "langchain-anthropic")
        span.set_attribute("demo.examples", 3)

        # Run different examples
        simple_chat_example()
        chain_example()
        streaming_example()

    print("\n" + "=" * 60)
    print("Demo complete!")
    print("\nCheck the collector logs to see the telemetry:")
    print("  docker logs -f otel-collector")


if __name__ == "__main__":
    main()
