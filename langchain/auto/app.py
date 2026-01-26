"""
Simple LangChain app with Anthropic API using OpenTelemetry auto-instrumentation.
This demonstrates automatic observability with zero manual instrumentation code.
"""

import os
from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# Load environment variables
load_dotenv()


def simple_chat_example():
    """Simple chat example with Anthropic."""
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

    print("Starting LangChain + Anthropic + OpenTelemetry Auto-Instrumentation Demo")
    print("=" * 70)
    print("Note: Telemetry is automatically captured via opentelemetry-instrument")
    print("=" * 70)

    # Run different examples
    simple_chat_example()
    chain_example()
    streaming_example()

    print("\n" + "=" * 70)
    print("Demo complete!")
    print("\nCheck the collector logs to see the telemetry:")
    print("  docker logs -f otel-collector")


if __name__ == "__main__":
    main()
