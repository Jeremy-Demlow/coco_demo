-- ============================================================
-- 04_create_agent.sql
-- Creates the Cost Analytics Cortex Agent with 3 tools:
-- 1. Analyst1 (text-to-SQL for cost data via semantic view)
-- 2. Search1 (FinOps recommendations via Cortex Search)
-- 3. CostForecaster (cost prediction via stored procedure)
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Create the Cortex Agent
-- NOTE: Uses JSON format for SPEC (not YAML)
-- ============================================================
CREATE OR REPLACE AGENT DEMO_AGENT_CLOUD_COST
    COMMENT = 'Cloud cost analytics agent with forecasting capabilities'
    SPEC = $$
{
  "models": {"orchestration": "auto"},
  "orchestration": {"budget": {"seconds": 900, "tokens": 400000}},
  "instructions": {
    "response": "Format responses for FinOps stakeholders:\n- Lead with cost figures and percentages\n- Use tables for service/department comparisons\n- Include period-over-period changes when relevant\n- End with optimization recommendations",
    "orchestration": "You are a FinOps analyst assistant. Help users understand and optimize cloud costs.\n\nTOOL SELECTION:\n- Use Analyst1 for: cost totals, breakdowns by service/region/department, trends, comparisons\n- Use Search1 for: cost optimization recommendations, rightsizing advice, FinOps best practices\n- Use CostForecaster for: predicting future costs for specific service+department combinations\n\nIMPORTANT:\n- Always show costs in dollars with 2 decimal places\n- Include percentage breakdowns for cost distributions\n- Compare to previous periods when analyzing trends"
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Analyst1",
        "description": "Analyzes cloud billing data using natural language to SQL.\n\nDATA COVERAGE:\n- 40,000+ billing records from AWS and Azure\n- Fields: BILLING_DATE, CLOUD_PROVIDER, SERVICE, REGION, DEPARTMENT, ENVIRONMENT, COST, USAGE_QUANTITY\n\nWHEN TO USE:\n- Cost totals and breakdowns\n- Service/department/region comparisons\n- Trend analysis over time\n- Top spenders analysis\n\nWHEN NOT TO USE:\n- Future cost predictions (use CostForecaster)\n- Optimization recommendations (use Search1)"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search1", 
        "description": "Searches FinOps recommendations and cost optimization insights.\n\nDATA COVERAGE:\n- Cost optimization recommendations for AWS and Azure\n- Categories: rightsizing, reserved instances, spot usage, storage optimization\n\nWHEN TO USE:\n- Finding cost reduction opportunities\n- Best practices for specific services\n- Recommendations by category or priority\n\nWHEN NOT TO USE:\n- Actual cost data queries (use Analyst1)\n- Future cost predictions (use CostForecaster)"
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "CostForecaster",
        "description": "Predicts future cloud costs for a specific service and department.\n\nRETURNS:\n- Historical average daily cost\n- Forecasted total for the period\n- Confidence interval (low/high)\n- Trend direction (increasing/stable)\n\nWHEN TO USE:\n- Budget planning questions\n- Forecasting specific service costs\n- Predicting department spend\n\nWHEN NOT TO USE:\n- Historical cost analysis (use Analyst1)\n- Optimization recommendations (use Search1)",
        "input_schema": {
          "type": "object",
          "properties": {
            "TARGET_SERVICE": {"type": "string", "description": "Cloud service to forecast, e.g. EC2, S3, Virtual Machines"},
            "TARGET_DEPARTMENT": {"type": "string", "description": "Department to forecast, e.g. Engineering, Data Science"},
            "FORECAST_DAYS": {"type": "integer", "description": "Days to forecast (default: 30)"}
          },
          "required": ["TARGET_SERVICE", "TARGET_DEPARTMENT"]
        }
      }
    }
  ],
  "tool_resources": {
    "Analyst1": {
      "semantic_view": "WORKSHOP_DB.DEMO.COST_SEMANTIC_VIEW",
      "execution_environment": {"type": "warehouse", "warehouse": "WORKSHOP_WH", "query_timeout": 299}
    },
    "Search1": {
      "search_service": "WORKSHOP_DB.DEMO.TEXT_SEARCH",
      "execution_environment": {"type": "warehouse", "warehouse": "WORKSHOP_WH", "query_timeout": 299}
    },
    "CostForecaster": {
      "type": "procedure",
      "identifier": "WORKSHOP_DB.DEMO.FORECAST_COST",
      "execution_environment": {"type": "warehouse", "warehouse": "WORKSHOP_WH"}
    }
  }
}
$$;

-- ============================================================
-- Verify Agent Created
-- ============================================================
SHOW AGENTS LIKE 'DEMO_AGENT_CLOUD_COST';
