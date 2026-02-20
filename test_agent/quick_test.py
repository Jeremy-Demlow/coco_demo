"""
Quick test script for the Cost Analytics Agent.
"""

import requests
import json

# Snowflake REST API endpoint (update with your account)
ACCOUNT_URL = "https://<your-account>.snowflakecomputing.com"
AGENT_ENDPOINT = f"{ACCOUNT_URL}/api/v2/cortex/agent/run"

def test_agent(question: str):
    """Send a question to the agent and print the response."""
    print(f"\n{'='*60}")
    print(f"Question: {question}")
    print('='*60)
    
    # In production, use proper authentication
    # This is a placeholder for testing
    print("Note: Update ACCOUNT_URL and authentication before running")
    print(f"Would send: {question}")

def main():
    """Run sample queries against the Cost Analytics Agent."""
    
    test_questions = [
        # Analytics questions
        "What was our total cloud spend last month?",
        "Show me the top 5 most expensive services",
        "Compare costs by department",
        
        # Recommendation questions  
        "How can we reduce our EC2 costs?",
        "Find high-priority optimization recommendations",
        
        # Forecasting questions
        "Forecast EC2 costs for Engineering for the next 30 days",
    ]
    
    for question in test_questions:
        test_agent(question)

if __name__ == "__main__":
    main()
