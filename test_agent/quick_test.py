#!/usr/bin/env python3
"""
Quick test of the Fraud Detection Agent.

Usage:
    python quick_test.py                           # Default question
    python quick_test.py "Your question here"      # Custom question
    python quick_test.py -v "Question"             # Verbose mode (show raw events)
"""
import sys
from agent_client import CortexAgentClient

# Configuration - update these for your environment
# Or use test_config.yaml for persistent configuration
CONFIG = {
    "account": "trb65519",
    "user": "jd_service_account_admin", 
    "private_key_path": "/Users/jdemlow/.snowflake/keys/snowflake_tf_key.p8",
    "database": "WORKSHOP_DB",
    "schema": "DEMO",
    "agent_name": "DEMO_AGENT",
}

DEFAULT_QUESTION = "Give me an executive summary of overall fraud status - total fraud rate, top risk areas, and 1-2 recommended actions."


def main():
    # Parse arguments
    verbose = "-v" in sys.argv or "--verbose" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    question = args[0] if args else DEFAULT_QUESTION
    
    # Initialize client
    client = CortexAgentClient(**CONFIG)
    
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
