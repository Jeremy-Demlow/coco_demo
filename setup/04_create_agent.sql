-- ============================================================
-- 04_create_agent.sql
-- Creates the Cost Analytics Cortex Agent with 3 tools:
-- 1. Analyst (text-to-SQL for cost data)
-- 2. Search (FinOps recommendations)
-- 3. CostForecaster (ML-based cost prediction)
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Create the Cortex Agent
-- ============================================================
CREATE OR REPLACE CORTEX AGENT DEMO_AGENT
    COMMENT = 'Cost analytics agent with forecasting capabilities'
    AGENT_SPEC = $$
name: CostAnalyticsAgent
description: |
  An intelligent agent for cloud cost analytics and forecasting.
  Combines SQL analytics, FinOps recommendations, and ML-powered cost predictions.
  
instructions: |
  You are a FinOps analyst assistant helping users understand and optimize their cloud costs.
  
  Use the available tools strategically:
  - Use Analyst1 for questions about historical costs, trends, breakdowns, and comparisons
  - Use Search1 to find cost optimization recommendations and FinOps best practices
  - Use CostForecaster to predict future costs for specific services or total spend
  
  When analyzing costs:
  - Always provide context (time period, comparison to previous periods)
  - Highlight anomalies or significant changes
  - Suggest optimization opportunities when relevant
  
  When forecasting:
  - Explain the basis for the forecast
  - Mention confidence levels and potential factors that could affect accuracy
  - Recommend actions based on the forecast
  
tools:
  - tool_spec:
      type: cortex_analyst
      name: Analyst1
      description: |
        Analyzes cloud billing data using natural language to SQL conversion.
        
        WHEN TO USE:
        - Questions about historical costs (e.g., "What was our AWS spend last month?")
        - Cost breakdowns by service, region, department, or account
        - Trend analysis (e.g., "How has EC2 cost changed over time?")
        - Comparisons (e.g., "Compare production vs development costs")
        - Anomaly investigation (e.g., "Why did S3 costs spike last week?")
        
        WHEN NOT TO USE:
        - Future cost predictions (use CostForecaster)
        - Cost optimization recommendations (use Search1)
        
        Example questions:
        - "What are our top 5 most expensive services?"
        - "Show monthly cost trend by cloud provider"
        - "Which department has the highest AWS spend?"
        - "Break down costs by environment for the Data Science team"
      semantic_model: "WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW"

  - tool_spec:
      type: cortex_search
      name: Search1
      description: |
        Searches FinOps recommendations and cost optimization insights.
        
        WHEN TO USE:
        - Finding cost reduction opportunities
        - Best practices for specific services (e.g., "How to reduce EC2 costs?")
        - Recommendations for rightsizing, reserved instances, or spot usage
        - General FinOps guidance
        
        WHEN NOT TO USE:
        - Querying actual cost data (use Analyst1)
        - Predicting future costs (use CostForecaster)
        
        Example queries:
        - "How can we reduce our EC2 costs?"
        - "What are the benefits of reserved instances?"
        - "Find recommendations for the Engineering department"
        - "Cost optimization for Azure Virtual Machines"
      search_service: "WORKSHOP_DB.DEMO.TEXT_SEARCH"
      max_results: 5
      title_column: "TITLE"
      id_column: "RECOMMENDATION_ID"
      filter_columns:
        - "CATEGORY"
        - "CLOUD_PROVIDER"
        - "SERVICE"
        - "PRIORITY"

  - tool_spec:
      type: generic
      name: CostForecaster
      description: |
        Predicts future cloud costs using historical patterns.
        
        WHEN TO USE:
        - Forecasting costs for budget planning
        - Predicting spend for specific services or departments
        - Estimating next month/quarter costs
        
        WHEN NOT TO USE:
        - Analyzing historical costs (use Analyst1)
        - Finding optimization recommendations (use Search1)
        
        Parameters:
        - TARGET_SERVICE: Cloud service name (e.g., "EC2", "S3", "Virtual Machines")
        - TARGET_DEPARTMENT: Department name (e.g., "Engineering", "Data Science")
        - FORECAST_DAYS: Number of days to forecast (default: 30)
        
        Example: Forecast EC2 costs for Engineering team for next 30 days
      input_schema:
        type: object
        properties:
          TARGET_SERVICE:
            type: string
            description: "The cloud service to forecast, e.g. EC2, S3, Virtual Machines"
          TARGET_DEPARTMENT:
            type: string
            description: "The department to forecast, e.g. Engineering, Data Science"
          FORECAST_DAYS:
            type: integer
            description: "Number of days to forecast (default: 30)"
        required:
          - TARGET_SERVICE
          - TARGET_DEPARTMENT

tool_resources:
  Analyst1:
    semantic_model: "WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW"
  Search1:
    search_service: "WORKSHOP_DB.DEMO.TEXT_SEARCH"
  CostForecaster:
    type: procedure
    identifier: "WORKSHOP_DB.DEMO.FORECAST_COST"
    execution_environment:
      type: warehouse
      warehouse: "WORKSHOP_WH"
$$;

-- ============================================================
-- Verify Agent Created
-- ============================================================
SHOW CORTEX AGENTS;
DESCRIBE CORTEX AGENT DEMO_AGENT;
