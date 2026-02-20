#!/usr/bin/env python3
"""Quick test of the Cost Analytics Agent."""

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

question = "What was our total cloud spend last month? Break it down by provider."

print(f"Question: {question}\n")
result = client.ask(question, verbose=False)
print(client.format_result(result))
