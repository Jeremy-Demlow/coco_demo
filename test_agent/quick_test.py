#!/usr/bin/env python3
"""Quick test of a single question."""

from agent_client import CortexAgentClient

CONFIG = {
    "account": "trb65519",
    "user": "jd_service_account_admin",
    "private_key_path": "/Users/jdemlow/.snowflake/keys/snowflake_tf_key.p8",
    "database": "WORKSHOP_DB",
    "schema": "DEMO",
    "agent_name": "DEMO_AGENT",
}

client = CortexAgentClient(**CONFIG)

question = "Give me an executive summary of overall fraud status - total fraud rate, top risk areas, and 1-2 recommended actions."

print(f"Question: {question}\n")
result = client.ask(question, verbose=False)
print(client.format_result(result))
