"""
Simple demo using only auto-instrumentation - no manual spans.
All LLM and HTTP calls are automatically traced.
"""

import os
from dotenv import load_dotenv
from anthropic import Anthropic

load_dotenv()


def analyze_sentiment(client: Anthropic, text: str) -> str:
    """Analyze sentiment of text using Claude."""
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
    return response.content[0].text.strip().lower()


def generate_response(client: Anthropic, user_query: str, sentiment: str) -> str:
    """Generate a response based on user query and sentiment."""
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

    return response.content[0].text


def process_customer_query(query: str):
    """Process customer query with sentiment analysis."""
    print(f"\nProcessing: {query}")

    client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

    sentiment = analyze_sentiment(client, query)
    print(f"Sentiment: {sentiment}")

    response = generate_response(client, query, sentiment)
    print(f"Response: {response}\n")


def main():
    """Main execution function."""
    if not os.getenv("ANTHROPIC_API_KEY"):
        print("ERROR: ANTHROPIC_API_KEY not found")
        return

    print("OpenLLMetry Auto-Instrumentation Demo")

    process_customer_query("I'm having trouble connecting to the API. Can you help?")
    process_customer_query("This service is amazing! I love how easy it is to use.")

    print("Demo complete - check Dash0 for traces")


if __name__ == "__main__":
    main()
