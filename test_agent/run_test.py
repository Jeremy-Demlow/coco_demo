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

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent.parent / "model"))

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
    """Get Snowpark session."""
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
            
            # Check expected columns
            if "expected_columns" in test_config:
                columns = [r.as_dict().keys() for r in result[:1]][0] if result else []
                for col in test_config["expected_columns"]:
                    if col not in columns:
                        raise ValueError(f"Missing column: {col}")
            
            # Check expected keys (for JSON results like procedures)
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
                    if hasattr(row, 'as_dict'):
                        print(f"     {row.as_dict()}")
                    else:
                        print(f"     {row}")
                        
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


def print_agent_questions(config: dict):
    """Print sample questions for testing in Snowsight."""
    print("\n" + "=" * 60)
    print("Sample Questions for Snowsight Testing")
    print("=" * 60)
    
    questions = config.get("agent_questions", {})
    
    for category, q_list in questions.items():
        print(f"\n{category.replace('_', ' ').title()}:")
        for q in q_list[:3]:
            print(f"  • {q}")


def main():
    parser = argparse.ArgumentParser(description="Test Cortex Agent components")
    parser.add_argument("--config", default="test_config.yaml", help="Config file path")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    args = parser.parse_args()
    
    # Find config file
    config_path = Path(args.config)
    if not config_path.is_absolute():
        config_path = Path(__file__).parent / args.config
    
    if not config_path.exists():
        print(f"ERROR: Config file not found: {config_path}")
        sys.exit(1)
    
    print(f"Loading config: {config_path}")
    config = load_config(config_path)
    
    # Get session
    print("Connecting to Snowflake...")
    session = get_session()
    
    agent_config = config.get("agent", {})
    session.sql(f"USE DATABASE {agent_config.get('database', 'WORKSHOP_DB')}").collect()
    session.sql(f"USE SCHEMA {agent_config.get('schema', 'DEMO')}").collect()
    
    # Check agent
    agent_ok = check_agent_exists(session, config)
    
    # Run component tests
    results = run_component_tests(session, config, args.verbose)
    
    # Print summary
    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"Agent: {'✓ OK' if agent_ok else '✗ NEEDS FIX'}")
    print(f"Components: {results['passed']} passed, {results['failed']} failed")
    
    # Print sample questions
    print_agent_questions(config)
    
    print("\n" + "=" * 60)
    print("Next Steps")
    print("=" * 60)
    print("1. Go to Snowsight → AI & ML → Cortex Agents")
    print(f"2. Select {agent_config.get('name', 'DEMO_AGENT_CLOUD_COST')}")
    print("3. Try the sample questions above")
    
    session.close()
    
    # Exit with error if any tests failed
    sys.exit(0 if results['failed'] == 0 and agent_ok else 1)


if __name__ == "__main__":
    main()
