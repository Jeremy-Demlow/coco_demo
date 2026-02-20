#!/usr/bin/env python3
"""Quick test of the Cost Analytics Agent.

Usage:
    python quick_test.py                           # Uses default question
    python quick_test.py "Your question here"     # Custom question
"""

import sys
from agent_client import CortexAgentClient

CONFIG = {
    "account": "trb65519",
    "user": "jd_service_account_admin",
    "private_key_path": "/Users/jdemlow/.snowflake/keys/snowflake_tf_key.p8",
    "database": "WORKSHOP_DB",
    "schema": "DEMO",
    "agent_name": "DEMO_AGENT_CLOUD_COST",
}

client = CortexAgentClient(**CONFIG)

# Use command-line argument if provided, otherwise use default
question = sys.argv[1] if len(sys.argv) > 1 else "What was our total cloud spend last month? Break it down by provider."

print(f"Question: {question}\n")
result = client.ask(question, verbose=False)
print(client.format_result(result))
