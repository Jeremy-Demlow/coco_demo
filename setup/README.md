# Cloud Cost Analytics Agent Demo

A **Snowflake Intelligence** demo powered by **Cortex Agents** for FinOps cloud cost analytics.

This demo showcases how to build an AI-powered cost analytics assistant using:
- **Cortex Analyst** - Natural language to SQL for billing data queries
- **Cortex Search** - Semantic search for cost optimization recommendations  
- **Cortex Agents** - Orchestrates multiple tools to answer complex questions

## What is Snowflake Intelligence?

Snowflake Intelligence is a suite of AI-powered capabilities that make data more accessible and actionable. This demo uses **Cortex Agents** - autonomous AI agents that can understand natural language questions, select appropriate tools, and synthesize answers from multiple data sources.

## Demo Features

| Capability | Tool | Example Question |
|------------|------|------------------|
| **Cost Analysis** | Cortex Analyst | "What was our total cloud spend by provider?" |
| **Recommendations** | Cortex Search | "How can we reduce EC2 costs?" |
| **Forecasting** | SQL Procedure | "Forecast next month costs for Compute" |

## FOCUS Billing Data

This demo uses **FOCUS-compliant** billing data (FinOps Open Cost and Usage Specification):
- Multi-cloud: AWS (65%) and Azure (35%)
- 50,000 billing records across 365 days
- 7 service categories: Compute, Storage, Databases, Networking, Analytics, Security, Management
- 4 cost types: BilledCost, EffectiveCost, ListCost, ContractedCost
- Cost allocation tags: Department, Environment

## Prerequisites

1. Snowflake account with SYSADMIN and ACCOUNTADMIN access
2. Database `WORKSHOP_DB` and schema `DEMO` created
3. Warehouse `WORKSHOP_WH` created
4. Snowflake CLI (`snow`) installed

## Quick Start

### 1. Generate FOCUS billing data

```bash
cd ../data
python generate_focus_data.py --rows 50000 --output focus_billing_data.parquet
```

### 2. Run setup scripts in order

```bash
# Create FOCUS-compliant billing table
snow sql -f 01_create_focus_table.sql

# Upload data to stage
snow stage copy ../data/focus_billing_data.parquet @WORKSHOP_DB.DEMO.BILLING_STAGE

# Load data from stage
snow sql -f 02_load_focus_data.sql

# Create Cortex Search service for recommendations
snow sql -f 03_create_search_service.sql

# Create semantic view for Cortex Analyst
snow sql -f 03b_create_focus_semantic_view.sql

# Create the Cortex Agent
snow sql -f 04_create_agent.sql

# Grant permissions
snow sql -f 05_grants.sql

# Create forecast procedure
snow sql -f 07_create_prediction_procedure.sql
```

### 3. Test the agent

```bash
cd ../test_agent

# Quick test with default question
python quick_test.py

# Custom questions
python quick_test.py "What is our total spend by service category?"
python quick_test.py "What are some ways to optimize storage costs?"
python quick_test.py "Forecast next month costs for Databases in Engineering"
```

## Project Structure

```
coco_demo/
├── data/
│   ├── generate_focus_data.py      # FOCUS billing data generator
│   └── focus_billing_data.parquet  # Generated billing data
├── setup/
│   ├── 01_create_focus_table.sql   # FOCUS-compliant table DDL
│   ├── 02_load_focus_data.sql      # Load from parquet
│   ├── 03_create_search_service.sql # Cost recommendations search
│   ├── 03b_create_focus_semantic_view.sql # Semantic view for Analyst
│   ├── 04_create_agent.sql         # Cortex Agent definition
│   ├── 05_grants.sql               # Permissions
│   └── 07_create_prediction_procedure.sql # Simple SQL forecast
├── test_agent/
│   ├── agent_client.py             # REST API client for agent
│   ├── quick_test.py               # One-liner test script
│   ├── run_test.py                 # Full test suite
│   └── test_config.yaml            # Test configuration
└── model/                          # (Optional) Model Registry demo
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Snowflake Intelligence                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Cortex Agent                            │   │
│  │              DEMO_AGENT_CLOUD_COST                        │   │
│  └──────────────┬───────────────┬───────────────┬───────────┘   │
│                 │               │               │                │
│        ┌────────▼────┐  ┌───────▼───────┐  ┌───▼───────────┐   │
│        │   Analyst1  │  │    Search1    │  │ CostForecaster│   │
│        │   (Analyst) │  │    (Search)   │  │  (Procedure)  │   │
│        └──────┬──────┘  └───────┬───────┘  └───────┬───────┘   │
│               │                 │                   │            │
│        ┌──────▼──────┐  ┌───────▼───────┐  ┌───────▼───────┐   │
│        │  Semantic   │  │    Cortex     │  │   FORECAST    │   │
│        │    View     │  │    Search     │  │    _COST      │   │
│        └──────┬──────┘  └───────┬───────┘  └───────────────┘   │
│               │                 │                                │
│        ┌──────▼──────┐  ┌───────▼───────┐                       │
│        │   FOCUS     │  │     COST      │                       │
│        │  _BILLING   │  │ RECOMMENDATIONS│                       │
│        └─────────────┘  └───────────────┘                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Key Configuration Notes

### Agent Tool Resources

The agent requires `execution_environment` in `tool_resources`:

```yaml
tool_resources:
  Analyst1:
    semantic_view: "WORKSHOP_DB.DEMO.COST_SEMANTIC_VIEW"
    execution_environment:
      type: warehouse
      warehouse: "WORKSHOP_WH"
      query_timeout: 299
```

### Tool Descriptions Best Practices

Each tool includes clear guidance for the agent:
- **WHEN TO USE**: Specific scenarios for this tool
- **WHEN NOT TO USE**: Redirect to other tools
- Field/metric coverage information

## Sample Queries

```
# Cost Analysis (uses Cortex Analyst)
"What was our total cloud spend last month?"
"Show me cost breakdown by service category"
"Which department has the highest cloud costs?"
"Compare AWS vs Azure spending"

# Recommendations (uses Cortex Search)
"How can we reduce EC2 costs?"
"What are some storage optimization tips?"
"Give me rightsizing recommendations"

# Forecasting (uses SQL procedure)
"Forecast next month costs for Compute in Engineering"
"What will our AWS spend be next quarter?"
```

## Learn More

- [Snowflake Cortex Agents Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [Cortex Analyst Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [FOCUS Specification](https://focus.finops.org/)
