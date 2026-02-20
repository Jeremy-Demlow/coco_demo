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
CREATE OR REPLACE AGENT DEMO_AGENT_CLOUD_COST
    COMMENT = 'Cloud cost analytics agent with forecasting capabilities'
    SPEC = $$
{
  "instructions": {
    "orchestration": "You are a FinOps analyst assistant helping users understand and optimize their cloud costs. Use Analyst1 for historical cost queries (breakdowns, trends, comparisons), Search1 for optimization recommendations, and CostForecaster for future cost predictions."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Analyst1",
        "description": "Analyzes cloud billing data using natural language to SQL. WHEN TO USE: Historical costs, breakdowns by service/region/department/account, trends, comparisons, anomaly investigation. WHEN NOT TO USE: Future predictions (use CostForecaster), optimization recommendations (use Search1)."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search1",
        "description": "Searches FinOps recommendations and cost optimization insights. WHEN TO USE: Cost reduction opportunities, rightsizing, reserved instances, spot usage recommendations. WHEN NOT TO USE: Actual cost data (use Analyst1), predictions (use CostForecaster)."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "CostForecaster",
        "description": "Predicts future cloud costs using historical patterns. WHEN TO USE: Budget planning, forecasting service/department spend, estimating next month/quarter costs. WHEN NOT TO USE: Historical costs (use Analyst1), recommendations (use Search1).",
        "input_schema": {
          "type": "object",
          "properties": {
            "TARGET_SERVICE": {
              "type": "string",
              "description": "Cloud service to forecast, e.g. EC2, S3, Virtual Machines"
            },
            "TARGET_DEPARTMENT": {
              "type": "string",
              "description": "Department to forecast, e.g. Engineering, Data Science"
            },
            "FORECAST_DAYS": {
              "type": "integer",
              "description": "Days to forecast (default: 30)"
            }
          },
          "required": ["TARGET_SERVICE", "TARGET_DEPARTMENT"]
        }
      }
    }
  ],
  "tool_resources": {
    "Analyst1": {
      "semantic_view": "WORKSHOP_DB.DEMO.COST_SEMANTIC_VIEW",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "WORKSHOP_WH"
      }
    },
    "Search1": {
      "search_service": "WORKSHOP_DB.DEMO.TEXT_SEARCH",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "WORKSHOP_WH"
      }
    },
    "CostForecaster": {
      "type": "procedure",
      "identifier": "WORKSHOP_DB.DEMO.FORECAST_COST",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "WORKSHOP_WH"
      }
    }
  }
}
$$;

-- ============================================================
-- Verify Agent Created
-- ============================================================
SHOW AGENTS;
DESCRIBE AGENT DEMO_AGENT_CLOUD_COST;
