#!/usr/bin/env python3
"""
Test the DEMO_AGENT_CLOUD_COST agent.
Uses the same credentials as Cortex Code (from ~/.snowflake/connections.toml)
"""

import sys
sys.path.insert(0, '/Users/jdemlow/Customers/Blackline/coco_demo/model')
sys.path.insert(0, '/Users/jdemlow/Customers/Blackline/coco_demo/test_agent')

from snowpark_session import create_snowpark_session
from agent_client import CortexAgentClient
import os
from pathlib import Path

def get_connection_config():
    """Read connection config from ~/.snowflake/connections.toml"""
    try:
        import tomllib
    except ImportError:
        import tomli as tomllib
    
    config_path = Path.home() / ".snowflake" / "config.toml"
    with open(config_path, "rb") as f:
        data = tomllib.load(f)
    
    # Get the myconnection config
    conn = data.get("myconnection", {})
    return {
        "account": conn.get("account", ""),
        "user": conn.get("user", ""),
        "private_key_path": conn.get("private_key_path", ""),
    }

def main():
    # Get config
    config = get_connection_config()
    print(f"Account: {config['account']}")
    print(f"User: {config['user']}")
    print(f"Key path: {config['private_key_path']}")
    
    if not config['private_key_path'] or not os.path.exists(os.path.expanduser(config['private_key_path'])):
        print("\nWARNING: No private key found. Testing with Snowpark instead...")
        test_with_snowpark()
        return
    
    # Create client
    client = CortexAgentClient(
        account=config['account'],
        user=config['user'],
        private_key_path=os.path.expanduser(config['private_key_path']),
        database="WORKSHOP_DB",
        schema="DEMO",
        agent_name="DEMO_AGENT_CLOUD_COST"
    )
    
    # Test questions
    questions = [
        "What was our total cloud spend last month?",
        "How can we reduce EC2 costs?",
        "Forecast EC2 costs for Engineering for 30 days",
    ]
    
    for q in questions:
        print(f"\n{'='*60}")
        print(f"Question: {q}")
        print('='*60)
        
        result = client.ask(q, verbose=True)
        print(client.format_result(result))

def test_with_snowpark():
    """Alternative test using Snowpark to verify agent components work"""
    session = create_snowpark_session()
    session.sql("USE DATABASE WORKSHOP_DB").collect()
    session.sql("USE SCHEMA DEMO").collect()
    
    print("\n" + "="*60)
    print("Testing Agent Components via Snowpark")
    print("="*60)
    
    # Test 1: Semantic view works
    print("\n1. Testing Semantic View (Analyst1 backend)...")
    try:
        result = session.sql("""
            SELECT CLOUD_PROVIDER, SUM(COST) as TOTAL_COST 
            FROM BILLING_DATA 
            WHERE BILLING_DATE >= DATEADD('month', -1, CURRENT_DATE())
            GROUP BY CLOUD_PROVIDER
        """).collect()
        print(f"   ✓ Semantic view data accessible: {len(result)} rows")
        for row in result:
            print(f"     {row['CLOUD_PROVIDER']}: ${row['TOTAL_COST']:,.2f}")
    except Exception as e:
        print(f"   ✗ Error: {e}")
    
    # Test 2: Search service works
    print("\n2. Testing Search Service (Search1 backend)...")
    try:
        result = session.sql("""
            SELECT TITLE, CATEGORY, PRIORITY 
            FROM COST_RECOMMENDATIONS 
            WHERE CLOUD_PROVIDER = 'AWS' 
            LIMIT 3
        """).collect()
        print(f"   ✓ Recommendations accessible: {len(result)} rows")
        for row in result:
            print(f"     [{row['PRIORITY']}] {row['TITLE']}")
    except Exception as e:
        print(f"   ✗ Error: {e}")
    
    # Test 3: Forecast procedure works
    print("\n3. Testing Forecast Procedure (CostForecaster backend)...")
    try:
        result = session.sql("""
            CALL FORECAST_COST('EC2', 'Engineering', 30)
        """).collect()
        print(f"   ✓ Forecast procedure works")
        import json
        forecast = json.loads(str(result[0][0]))
        print(f"     Service: {forecast.get('service')}")
        print(f"     Department: {forecast.get('department')}")
        print(f"     Forecasted Total: ${forecast.get('forecasted_total', 0):,.2f}")
    except Exception as e:
        print(f"   ✗ Error: {e}")
    
    # Test 4: Agent exists
    print("\n4. Checking Agent...")
    try:
        result = session.sql("SHOW AGENTS LIKE 'DEMO_AGENT_CLOUD_COST'").collect()
        if result:
            print(f"   ✓ Agent exists: {result[0]['name']}")
        else:
            print("   ✗ Agent not found")
    except Exception as e:
        print(f"   ✗ Error: {e}")
    
    print("\n" + "="*60)
    print("Component Test Complete")
    print("="*60)
    print("\nTo fully test the agent, use Snowsight:")
    print("1. Go to AI & ML → Cortex Agents")
    print("2. Select DEMO_AGENT_CLOUD_COST")
    print("3. Try: 'What was our total cloud spend last month?'")
    
    session.close()

if __name__ == "__main__":
    main()
