-- ============================================================
-- 04_create_agent.sql
-- Creates DEMO_AGENT_CLOUD_COST with Cortex Analyst, Cortex Search, and Forecasting tools
-- 
-- IMPORTANT: Uses FROM SPECIFICATION with YAML format
-- Prerequisites: Run 03b_create_semantic_view.sql and 07_create_prediction_procedure.sql first
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

CREATE OR REPLACE AGENT DEMO_AGENT_CLOUD_COST
    COMMENT = 'Cloud cost analytics agent with forecasting capabilities'
    FROM SPECIFICATION
    $$
    models:
      orchestration: auto

    orchestration:
      budget:
        seconds: 900
        tokens: 400000

    instructions:
      orchestration: |
        You are a FinOps analyst assistant. Help users understand and optimize cloud costs.

        RESPONSE STYLE:
        - Lead with cost figures and percentages
        - Use tables for service/department comparisons
        - Include period-over-period changes when relevant
        - End with optimization recommendations when appropriate

        TOOL SELECTION:
        - Use Analyst1 for: cost totals, breakdowns by service/region/department, trends, comparisons
        - Use Search1 for: cost optimization recommendations, rightsizing advice, FinOps best practices
        - Use CostForecaster for: predicting future costs for specific service+department combinations

        IMPORTANT RULES:
        - Always show costs in dollars with 2 decimal places
        - Include percentage breakdowns for cost distributions
        - Compare to previous periods when analyzing trends
        - For forecasts, always mention confidence intervals

      response: |
        Format responses for FinOps stakeholders:
        - Lead with the key cost figure or insight
        - Use tables for 3+ comparable items
        - Include percentage changes from prior period
        - End with "Recommendations:" when relevant

    tools:
      - tool_spec:
          type: cortex_analyst_text_to_sql
          name: Analyst1
          description: |
            Analyzes cloud billing data using natural language to SQL.

            DATA COVERAGE:
            - 40,000+ billing records from AWS and Azure
            - Fields: BILLING_DATE, CLOUD_PROVIDER, SERVICE, REGION, DEPARTMENT, ENVIRONMENT, COST, USAGE_QUANTITY
            - Date range: 365 days of historical data

            WHEN TO USE:
            - Cost totals and breakdowns by any dimension
            - Service/department/region comparisons
            - Trend analysis over time
            - Top spenders analysis
            - Anomaly investigation

            WHEN NOT TO USE:
            - Future cost predictions (use CostForecaster)
            - Optimization recommendations (use Search1)

      - tool_spec:
          type: cortex_search
          name: Search1
          description: |
            Searches FinOps recommendations and cost optimization insights.

            DATA COVERAGE:
            - Cost optimization recommendations for AWS and Azure
            - Categories: Rightsizing, Reserved Instances, Storage, Spot Usage
            - Priority levels: High, Medium, Low
            - Potential savings estimates

            WHEN TO USE:
            - Finding cost reduction opportunities
            - Best practices for specific services
            - Recommendations by category or priority
            - Service-specific optimization guidance

            WHEN NOT TO USE:
            - Actual cost data queries (use Analyst1)
            - Future cost predictions (use CostForecaster)

      - tool_spec:
          type: generic
          name: CostForecaster
          description: |
            Predicts future cloud costs for a specific service and department.

            RETURNS:
            - Historical average daily cost
            - Forecasted total for the period
            - Confidence interval (low/high estimates)
            - Trend direction (increasing/stable/decreasing)

            WHEN TO USE:
            - Budget planning questions
            - Forecasting specific service costs
            - Predicting department spend
            - Estimating next month/quarter costs

            WHEN NOT TO USE:
            - Historical cost analysis (use Analyst1)
            - Optimization recommendations (use Search1)
          input_schema:
            type: object
            properties:
              TARGET_SERVICE:
                type: string
                description: "Cloud service to forecast, e.g. EC2, S3, Virtual Machines"
              TARGET_DEPARTMENT:
                type: string
                description: "Department to forecast, e.g. Engineering, Data Science"
              FORECAST_DAYS:
                type: integer
                description: "Days to forecast (default: 30)"
            required:
              - TARGET_SERVICE
              - TARGET_DEPARTMENT

    tool_resources:
      Analyst1:
        semantic_view: "WORKSHOP_DB.DEMO.COST_SEMANTIC_VIEW"
        execution_environment:
          type: warehouse
          warehouse: "WORKSHOP_WH"
          query_timeout: 299
      Search1:
        search_service: "WORKSHOP_DB.DEMO.TEXT_SEARCH"
        execution_environment:
          type: warehouse
          warehouse: "WORKSHOP_WH"
          query_timeout: 299
      CostForecaster:
        type: procedure
        identifier: "WORKSHOP_DB.DEMO.FORECAST_COST"
        execution_environment:
          type: warehouse
          warehouse: "WORKSHOP_WH"
    $$;

-- Verify agent was created
SHOW AGENTS LIKE 'DEMO_AGENT_CLOUD_COST' IN SCHEMA WORKSHOP_DB.DEMO;
