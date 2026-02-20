"""
Test cost analytics questions against the agent.
"""

# Sample questions for testing the Cost Analytics Agent

COST_ANALYTICS_QUESTIONS = [
    # Basic cost queries
    "What was our total cloud spend last month?",
    "Show me the top 10 most expensive services",
    "What is the daily cost trend over the past 30 days?",
    
    # Breakdown queries
    "Break down costs by cloud provider",
    "Which department has the highest AWS spend?",
    "Compare production vs non-production costs",
    "Show costs by region for EC2",
    
    # Trend analysis
    "How has our S3 spend changed over the past 6 months?",
    "What's the month-over-month cost growth?",
    "Which services are growing fastest?",
    
    # Anomaly investigation
    "Were there any cost spikes last week?",
    "Why did EC2 costs increase in us-west-2?",
]

RECOMMENDATION_QUESTIONS = [
    "How can we reduce our EC2 costs?",
    "What reserved instance opportunities do we have?",
    "Find rightsizing recommendations for Engineering",
    "Show high-priority cost optimization recommendations",
    "What Azure cost savings are available?",
]

FORECAST_QUESTIONS = [
    "Forecast EC2 costs for Engineering for the next 30 days",
    "What will our total AWS spend be next month?",
    "Predict S3 costs for Data Science for 60 days",
    "Forecast Azure Virtual Machines costs for Platform team",
]

if __name__ == "__main__":
    print("Cost Analytics Test Questions")
    print("="*50)
    
    print("\n📊 Analytics Questions:")
    for q in COST_ANALYTICS_QUESTIONS:
        print(f"  - {q}")
    
    print("\n💡 Recommendation Questions:")
    for q in RECOMMENDATION_QUESTIONS:
        print(f"  - {q}")
    
    print("\n🔮 Forecast Questions:")
    for q in FORECAST_QUESTIONS:
        print(f"  - {q}")
