#!/usr/bin/env python3
"""
Agent Test Runner - YAML-configurable test framework for Cortex Agents.

Usage:
    python run_test.py                          # Use default config
    python run_test.py --config my_config.yaml  # Use custom config
    python run_test.py --verbose                # Show detailed output
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "model"))

from agent_client import CortexAgentClient


def load_config(config_path: str) -> dict:
    """Load YAML configuration file."""
    try:
        import yaml
    except ImportError:
        print("ERROR: PyYAML required. Install with: pip install pyyaml")
        sys.exit(1)
    
    with open(config_path) as f:
        return yaml.safe_load(f)


def get_session():
    """Get Snowpark session for component tests."""
    from snowpark_session import create_snowpark_session
    return create_snowpark_session()


def run_component_tests(session, config: dict, verbose: bool = False) -> dict:
    """Run component tests to verify backend resources."""
    results = {"passed": 0, "failed": 0, "tests": []}
    
    print("\n" + "=" * 60)
    print("Component Tests")
    print("=" * 60)
    
    for test_id, test_config in config.get("component_tests", {}).items():
        name = test_config.get("name", test_id)
        query = test_config.get("query", "").strip()
        
        print(f"\n{test_id}: {name}")
        
        try:
            result = session.sql(query).collect()
            
            if "expected_columns" in test_config:
                columns = [r.as_dict().keys() for r in result[:1]][0] if result else []
                for col in test_config["expected_columns"]:
                    if col not in columns:
                        raise ValueError(f"Missing column: {col}")
            
            if "expected_keys" in test_config and result:
                json_result = json.loads(str(result[0][0]))
                for key in test_config["expected_keys"]:
                    if key not in json_result:
                        raise ValueError(f"Missing key: {key}")
            
            print(f"   ✓ PASSED ({len(result)} rows)")
            results["passed"] += 1
            results["tests"].append({"name": name, "status": "passed", "rows": len(result)})
            
            if verbose and result:
                for row in result[:3]:
                    print(f"     {row.as_dict() if hasattr(row, 'as_dict') else row}")
                        
        except Exception as e:
            print(f"   ✗ FAILED: {e}")
            results["failed"] += 1
            results["tests"].append({"name": name, "status": "failed", "error": str(e)})
    
    return results


def check_agent_exists(session, config: dict) -> bool:
    """Check if the agent exists and has a valid spec."""
    agent_config = config.get("agent", {})
    database = agent_config.get("database", "WORKSHOP_DB")
    schema = agent_config.get("schema", "DEMO")
    name = agent_config.get("name", "DEMO_AGENT_CLOUD_COST")
    
    print(f"\nAgent: {database}.{schema}.{name}")
    
    try:
        result = session.sql(f"DESCRIBE AGENT {database}.{schema}.{name}").collect()
        if result:
            row = result[0].as_dict()
            agent_spec = row.get("agent_spec", "")
            
            if agent_spec:
                spec = json.loads(agent_spec)
                tools = spec.get("tools", [])
                print(f"   ✓ Agent exists with {len(tools)} tools")
                for tool in tools:
                    tool_name = tool.get("tool_spec", {}).get("name", "unknown")
                    tool_type = tool.get("tool_spec", {}).get("type", "unknown")
                    print(f"     - {tool_name} ({tool_type})")
                return True
            else:
                print("   ✗ Agent exists but spec is EMPTY")
                return False
        else:
            print("   ✗ Agent not found")
            return False
            
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False


def test_agent_invocation(config: dict, verbose: bool = False) -> bool:
    """Actually invoke the agent with a test question via REST API."""
    agent_config = config.get("agent", {})
    auth_config = config.get("auth", {})
    
    print(f"\n" + "=" * 60)
    print("Agent Invocation Test (REST API)")
    print("=" * 60)
    
    test_question = config.get("agent_test_question", "What was our total cloud spend last month?")
    print(f"\nQuestion: {test_question}")
    
    try:
        client = CortexAgentClient(
            account=auth_config.get("account", "trb65519"),
            user=auth_config.get("user", "jd_service_account_admin"),
            private_key_path=auth_config.get("private_key_path", "/Users/jdemlow/.snowflake/keys/snowflake_tf_key.p8"),
            database=agent_config.get("database", "WORKSHOP_DB"),
            schema=agent_config.get("schema", "DEMO"),
            agent_name=agent_config.get("name", "DEMO_AGENT_CLOUD_COST"),
        )
        
        result = client.ask(test_question, verbose=verbose)
        
        if result.get("error"):
            print(f"   ✗ Error: {result['error']}")
            return False
        
        if result.get("answer"):
            print(f"   ✓ Agent responded in {result.get('duration', 0):.1f}s")
            print(f"   Tools: {', '.join(result.get('tools_used', [])) or 'none'}")
            if verbose:
                preview = result['answer'][:300].replace('\n', '\n   ')
                print(f"\n   {preview}...")
            return True
        else:
            print(f"   ✗ No answer returned")
            return False
            
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False


def print_sample_questions(config: dict):
    """Print sample questions for manual testing."""
    print("\n" + "=" * 60)
    print("Sample Questions")
    print("=" * 60)
    
    for category, questions in config.get("agent_questions", {}).items():
        print(f"\n{category.replace('_', ' ').title()}:")
        for q in questions[:3]:
            print(f"  • {q}")


def main():
    parser = argparse.ArgumentParser(description="Test Cortex Agent")
    parser.add_argument("--config", default="test_config.yaml", help="Config file")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--skip-invoke", action="store_true", help="Skip agent invocation test")
    args = parser.parse_args()
    
    config_path = Path(args.config)
    if not config_path.is_absolute():
        config_path = Path(__file__).parent / args.config
    
    if not config_path.exists():
        print(f"ERROR: Config not found: {config_path}")
        sys.exit(1)
    
    print(f"Loading: {config_path}")
    config = load_config(config_path)
    
    print("Connecting to Snowflake...")
    session = get_session()
    
    agent_config = config.get("agent", {})
    session.sql(f"USE DATABASE {agent_config.get('database', 'WORKSHOP_DB')}").collect()
    session.sql(f"USE SCHEMA {agent_config.get('schema', 'DEMO')}").collect()
    
    # Check agent spec
    agent_ok = check_agent_exists(session, config)
    
    # Run component tests
    results = run_component_tests(session, config, args.verbose)
    
    # Invoke agent via REST API
    invoke_ok = True
    if not args.skip_invoke:
        invoke_ok = test_agent_invocation(config, args.verbose)
    
    # Summary
    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"Agent Spec: {'✓ OK' if agent_ok else '✗ FAILED'}")
    print(f"Components: {results['passed']}/{results['passed'] + results['failed']} passed")
    if not args.skip_invoke:
        print(f"Invocation: {'✓ OK' if invoke_ok else '✗ FAILED'}")
    
    print_sample_questions(config)
    
    session.close()
    sys.exit(0 if results['failed'] == 0 and agent_ok and invoke_ok else 1)


if __name__ == "__main__":
    main()
