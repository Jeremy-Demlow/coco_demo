# Cloud Cost Analytics Agent - Implementation Status

## Overview

A Cortex Agent for cloud cost analytics and forecasting, combining:
- **Cortex Analyst** (text-to-SQL) for billing data queries
- **Cortex Search** for FinOps recommendations
- **Cost Forecasting** for budget predictions

---

## Current Status

### ✅ WORKING Components

| Component | Object | Status | Notes |
|-----------|--------|--------|-------|
| Billing Data | `BILLING_DATA` | ✅ 40,150 rows | AWS + Azure, 365 days |
| Recommendations | `COST_RECOMMENDATIONS` | ✅ 10 rows | FinOps best practices |
| Semantic View | `COST_SEMANTIC_VIEW` | ✅ Working | Dimensions + metrics defined |
| Search Service | `TEXT_SEARCH` | ✅ Working | Indexes recommendations |
| Forecast Procedure | `FORECAST_COST` | ✅ Working | Returns forecasts |
| Agent | `DEMO_AGENT_CLOUD_COST` | ✅ Created | Test in Snowsight |

### ⚠️ TODO - Not Yet Done

| Item | Description | Priority |
|------|-------------|----------|
| **Register ML Model** | Train and register `COST_FORECASTING_MODEL` to model registry | High |
| **Use Model in Procedure** | Update `FORECAST_COST` to call registered model instead of SQL calculations | High |
| **Test Agent in Snowsight** | Verify all 3 tools work via UI | High |
| **Model Monitor** | Set up monitoring for forecast accuracy | Medium |

---

## Snowflake Objects

| Object | Type | Status |
|--------|------|--------|
| `WORKSHOP_DB.DEMO.BILLING_DATA` | Table | ✅ Created |
| `WORKSHOP_DB.DEMO.COST_RECOMMENDATIONS` | Table | ✅ Created |
| `WORKSHOP_DB.DEMO.COST_SEMANTIC_VIEW` | Semantic View | ✅ Created |
| `WORKSHOP_DB.DEMO.TEXT_SEARCH` | Cortex Search | ✅ Created |
| `WORKSHOP_DB.DEMO.FORECAST_COST` | Procedure | ✅ Created |
| `WORKSHOP_DB.DEMO.DEMO_AGENT_CLOUD_COST` | Cortex Agent | ✅ Created |
| `WORKSHOP_DB.DEMO.COST_FORECASTING_MODEL` | ML Model | ❌ Not registered |
| `WORKSHOP_DB.DEMO.COST_MODEL_MONITOR` | Model Monitor | ❌ Not created |

---

## Test the Agent

### In Snowsight
1. Go to **AI & ML → Cortex Agents**
2. Select **DEMO_AGENT_CLOUD_COST**
3. Try these questions:

**Analyst1 (Cost Data):**
- "What was our total cloud spend last month?"
- "Show me the top 5 most expensive services"
- "Compare costs by department"

**Search1 (Recommendations):**
- "How can we reduce EC2 costs?"
- "Find high-priority optimization recommendations"

**CostForecaster (Predictions):**
- "Forecast EC2 costs for Engineering for 30 days"

### Via Python
```bash
cd test_agent && python run_test.py
```

---

## Files

```
setup/
├── 01_create_table.sql           # BILLING_DATA table
├── 02_load_from_stage.sql        # Load CSV data
├── 03_create_search_service.sql  # Recommendations + TEXT_SEARCH
├── 03b_create_semantic_view.sql  # COST_SEMANTIC_VIEW
├── 04_create_agent.sql           # DEMO_AGENT_CLOUD_COST
├── 05_grants.sql                 # Permissions
└── 07_create_prediction_procedure.sql  # FORECAST_COST

data/
└── generate_data.py              # Generate synthetic billing data

model/
├── cost_forecast_model.py        # Train XGBoost model (TODO: run this)
└── snowpark_session.py           # Snowpark session helper

test_agent/
├── agent_client.py               # REST API client
├── run_test.py                   # Component test script
└── test_cost_questions.py        # Sample questions
```

---

## Quick Commands

```bash
# Generate data
cd data && python generate_data.py

# Upload to Snowflake
snow stage copy data/billing_data.csv @WORKSHOP_DB.DEMO.DATA_STAGE --connection myconnection

# Test agent components
cd test_agent && python run_test.py

# Train model (TODO)
cd model && python cost_forecast_model.py
```

---

## Notes

### Agent Syntax
- Use `CREATE AGENT` (not `CREATE CORTEX AGENT`)
- Use `SPEC = $$...$$` (not `AGENT_SPEC`)
- Spec must be JSON format (not YAML)
- Include `models`, `orchestration`, `instructions`, `tools`, `tool_resources`

### Semantic View Syntax
- Use `DIMENSIONS` / `METRICS` syntax (not YAML)
- Each dimension/metric needs `TABLE`, `EXPRESSION`, `COMMENT`
- Synonyms help with natural language matching

### Model Registry
- Model must be trained and registered before procedure can use it
- Current procedure uses SQL calculations as fallback
