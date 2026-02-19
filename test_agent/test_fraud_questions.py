#!/usr/bin/env python3
"""
Test DEMO_AGENT with the 3 fraud analysis questions.
"""

from agent_client import CortexAgentClient

# Configuration - matches ~/.snowflake/config.toml
CONFIG = {
    "account": "trb65519",
    "user": "jd_service_account_admin",
    "private_key_path": "/Users/jdemlow/.snowflake/keys/snowflake_tf_key.p8",
    "database": "WORKSHOP_DB",
    "schema": "DEMO",
    "agent_name": "DEMO_AGENT",
}

# Test questions
QUESTIONS = [
    "What are the top 5 fraud transactions by amount? List the transaction IDs and risk drivers.",
    "What patterns best explain fraudulent transactions? Show the strongest signals.",
    "Give me a 30-second executive summary with 1-2 recommended actions.",
]


def main():
    print("Testing DEMO_AGENT - Transaction Fraud Analysis")
    print("=" * 60)
    
    client = CortexAgentClient(**CONFIG)
    
    for i, question in enumerate(QUESTIONS, 1):
        print(f"\n{'#'*60}")
        print(f"TEST {i}: {question}")
        print('#'*60)
        
        result = client.ask(question, verbose=True)
        print(client.format_result(result))


if __name__ == "__main__":
    main()
