#!/usr/bin/env python3
"""
Test DEMO_AGENT with the 3 fraud analysis questions.

Configuration:
    Uses Snowflake connection from environment variables:
    - SNOWFLAKE_ACCOUNT
    - SNOWFLAKE_USER  
    - SNOWFLAKE_PRIVATE_KEY_PATH
    - SNOWFLAKE_DATABASE (default: WORKSHOP_DB)
    - SNOWFLAKE_SCHEMA (default: DEMO)
    - SNOWFLAKE_AGENT_NAME (default: DEMO_AGENT)
"""
import os
import sys
from pathlib import Path

# Add parent dir to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from agent_client import CortexAgentClient


def get_config():
    """Get configuration from environment variables."""
    config = {
        "account": os.environ.get("SNOWFLAKE_ACCOUNT"),
        "user": os.environ.get("SNOWFLAKE_USER"),
        "private_key_path": os.environ.get("SNOWFLAKE_PRIVATE_KEY_PATH"),
        "database": os.environ.get("SNOWFLAKE_DATABASE", "WORKSHOP_DB"),
        "schema": os.environ.get("SNOWFLAKE_SCHEMA", "DEMO"),
        "agent_name": os.environ.get("SNOWFLAKE_AGENT_NAME", "DEMO_AGENT"),
    }
    
    # Check required fields
    missing = [k for k in ["account", "user", "private_key_path"] if not config[k]]
    if missing:
        print("ERROR: Missing required environment variables:")
        print(f"  SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PRIVATE_KEY_PATH")
        print("\nSet them with:")
        print("  export SNOWFLAKE_ACCOUNT='your_account'")
        print("  export SNOWFLAKE_USER='your_user'")
        print("  export SNOWFLAKE_PRIVATE_KEY_PATH='/path/to/key.p8'")
        sys.exit(1)
    
    return config


# Test questions
QUESTIONS = [
    "What are the top 5 fraud transactions by amount? List the transaction IDs and risk drivers.",
    "What patterns best explain fraudulent transactions? Show the strongest signals.",
    "Give me a 30-second executive summary with 1-2 recommended actions.",
]


def main():
    print("Testing DEMO_AGENT - Transaction Fraud Analysis")
    print("=" * 60)
    
    config = get_config()
    client = CortexAgentClient(**config)
    
    for i, question in enumerate(QUESTIONS, 1):
        print(f"\n{'#'*60}")
        print(f"TEST {i}: {question}")
        print('#'*60)
        
        result = client.ask(question, verbose=True)
        print(client.format_result(result))


if __name__ == "__main__":
    main()
