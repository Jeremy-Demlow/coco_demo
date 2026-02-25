#!/usr/bin/env python3
"""
Quick test of the Fraud Detection Agent.

Usage:
    python quick_test.py                           # Default question
    python quick_test.py "Your question here"      # Custom question
    python quick_test.py -v "Question"             # Verbose mode (show raw events)

Configuration:
    Uses Snowflake connection from:
    1. SNOWFLAKE_* environment variables
    2. ~/.snowflake/config.toml (default connection)
"""
import os
import sys
from pathlib import Path

# Add parent dir to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from agent_client import CortexAgentClient


def get_config():
    """
    Get configuration from environment variables.
    Falls back to prompting user if not set.
    """
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


DEFAULT_QUESTION = "Give me an executive summary of overall fraud status - total fraud rate, top risk areas, and 1-2 recommended actions."


def main():
    # Parse arguments
    verbose = "-v" in sys.argv or "--verbose" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    question = args[0] if args else DEFAULT_QUESTION
    
    # Get config from environment
    config = get_config()
    
    # Initialize client
    client = CortexAgentClient(**config)
    
    print(f"Question: {question}\n")
    print("Asking agent..." + (" (verbose mode)" if verbose else ""))
    
    # Call agent
    result = client.ask(question, verbose=verbose)
    
    # Display result
    print(client.format_result(result))
    
    # In verbose mode, show raw events
    if verbose and result.get("raw_events"):
        print("\n--- Raw Events ---")
        for event in result["raw_events"][:10]:
            print(f"  {event['event']}: {str(event['data'])[:100]}...")


if __name__ == "__main__":
    main()
