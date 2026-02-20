# Cloud Cost Analytics Agent

A **Snowflake Intelligence** demo powered by **Cortex Agents** for FinOps cloud cost analytics.

This agent answers natural language questions about cloud spending using FOCUS-compliant billing data, provides cost optimization recommendations, and forecasts future costs.

## Snowflake Intelligence

This demo showcases **Snowflake Intelligence** - AI-powered capabilities that make data accessible through natural language. The agent orchestrates three tools:

| Tool | Powered By | Capability |
|------|-----------|------------|
| **Analyst1** | Cortex Analyst | Natural language → SQL for cost queries |
| **Search1** | Cortex Search | Semantic search for FinOps recommendations |
| **CostForecaster** | SQL Procedure | Cost forecasting with confidence intervals |

## Quick Start

```bash
# 1. Setup Python environment
python3 -m venv .venv && source .venv/bin/activate
pip install pandas pyarrow

# 2. Generate FOCUS-compliant billing data
cd data && python generate_focus_data.py --rows 50000

# 3. Upload to Snowflake stage
snow stage copy focus_billing_data.parquet @WORKSHOP_DB.DEMO.BILLING_STAGE

# 4. Run SQL setup scripts (in order)
cd ../setup
snow sql -f 01_create_focus_table.sql
snow sql -f 02_load_focus_data.sql
snow sql -f 03_create_search_service.sql
snow sql -f 03b_create_focus_semantic_view.sql
snow sql -f 04_create_agent.sql
snow sql -f 05_grants.sql
snow sql -f 07_create_prediction_procedure.sql

# 5. Test the agent
cd ../test_agent && python quick_test.py
```

## Sample Questions

**Cost Analytics** (Cortex Analyst)
- "What was our total cloud spend by provider?"
- "Show me the top 5 most expensive services"
- "Compare costs by department"
- "What's our month-over-month cost trend?"

**Recommendations** (Cortex Search)
- "How can we reduce EC2 costs?"
- "What are some storage optimization tips?"
- "Find rightsizing recommendations"

**Forecasting** (SQL Procedure)
- "Forecast next month costs for Compute in Engineering"
- "What will our AWS spend be in 30 days?"

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

## Project Structure

```
coco_demo/
├── data/
│   ├── generate_focus_data.py      # FOCUS billing data generator
│   └── focus_billing_data.parquet  # Generated data (50K rows)
├── setup/
│   ├── 01_create_focus_table.sql   # FOCUS-compliant table
│   ├── 02_load_focus_data.sql      # Load from stage
│   ├── 03_create_search_service.sql # Recommendations search
│   ├── 03b_create_focus_semantic_view.sql # For Cortex Analyst
│   ├── 04_create_agent.sql         # Agent definition
│   ├── 05_grants.sql               # Permissions
│   ├── 07_create_prediction_procedure.sql # SQL forecast
│   └── README.md                   # Setup documentation
├── test_agent/
│   ├── agent_client.py             # REST API client
│   ├── quick_test.py               # Quick test script
│   ├── run_test.py                 # Full test suite
│   └── test_config.yaml            # Configuration
└── model/                          # (Optional) Model Registry demo
```

## FOCUS Billing Data

This demo uses **FOCUS-compliant** data (FinOps Open Cost and Usage Specification):

- **Providers**: AWS (65%), Azure (35%)
- **Records**: 50,000 billing line items
- **Time Range**: 365 days
- **Service Categories**: Compute, Storage, Databases, Networking, Analytics, Security, Management
- **Cost Types**: BilledCost, EffectiveCost, ListCost, ContractedCost
- **Allocation Tags**: Department, Environment, Cost Center

## Snowflake Objects

| Object | Type | Purpose |
|--------|------|---------|
| `FOCUS_BILLING` | Table | FOCUS-compliant billing data |
| `BILLING_DATA` | View | Simplified view for queries |
| `COST_SEMANTIC_VIEW` | Semantic View | Powers Cortex Analyst |
| `TEXT_SEARCH` | Cortex Search | FinOps recommendations |
| `DEMO_AGENT_CLOUD_COST` | Cortex Agent | Orchestrates all tools |
| `FORECAST_COST` | Procedure | Cost forecasting |

## Testing the Agent

```bash
# Default question
python test_agent/quick_test.py

# Custom question
python test_agent/quick_test.py "What is our total spend by service category?"
```

## Learn More

- [Snowflake Intelligence](https://www.snowflake.com/en/data-cloud/snowflake-intelligence/)
- [Cortex Agents Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [Cortex Analyst Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [FOCUS Specification](https://focus.finops.org/)
