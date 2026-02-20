# Cloud Cost Analytics Agent

A Snowflake Cortex Agent for cloud cost analytics and forecasting, combining text-to-SQL analytics, FinOps recommendations search, and ML-powered cost predictions.

## Quick Start

```bash
# 1. Setup Python environment
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2. Generate synthetic billing data
cd data && python generate_data.py

# 3. Upload to Snowflake stage
snow stage copy data/billing_data.csv @WORKSHOP_DB.DEMO.DATA_STAGE --connection myconnection

# 4. Run SQL setup scripts (in Snowflake, in order)
# setup/01_create_table.sql through setup/09_create_monitor.sql

# 5. Test the agent
cd test_agent && python quick_test.py
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  COST ANALYTICS AGENT                       │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
│  │  Analyst1   │  │  Search1    │  │   CostForecaster     │ │
│  │ (text-SQL)  │  │ (FinOps)    │  │   (ML forecast)      │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬───────────┘ │
└─────────┼────────────────┼───────────────────┼──────────────┘
          │                │                   │
          ▼                ▼                   ▼
   ┌────────────┐   ┌────────────┐   ┌─────────────────────┐
   │ SEMANTIC   │   │ TEXT_SEARCH│   │ FORECAST_COST       │
   │ VIEW       │   │ (Recs)     │   │ (Procedure)         │
   └────────────┘   └────────────┘   └─────────────────────┘
```

## Sample Questions

**Cost Analytics (Analyst1)**
- "What was our total AWS spend last month?"
- "Show me the top 10 most expensive services"
- "Compare costs by department for Q4"
- "Which region has the highest EC2 costs?"

**Recommendations (Search1)**
- "How can we reduce our EC2 costs?"
- "Find rightsizing recommendations for the Engineering team"
- "What reserved instance opportunities do we have?"

**Forecasting (CostForecaster)**
- "Forecast next month's S3 costs for Data Science"
- "What will our total Azure spend be in 30 days?"
- "Predict EC2 costs for the Platform team"

## Project Structure

```
coco_demo/
├── data/               # Data generation
│   └── generate_data.py
├── model/              # ML training
│   ├── cost_forecast_model.py
│   └── snowpark_session.py
├── setup/              # SQL scripts (run in order)
│   ├── 01_create_table.sql
│   ├── 02_load_from_stage.sql
│   ├── 03_create_search_service.sql
│   ├── 03b_create_semantic_view.sql
│   ├── 04_create_agent.sql
│   ├── 05_grants.sql
│   ├── 06_populate_fraud_labels.sql
│   ├── 07_create_prediction_procedure.sql
│   ├── 08_batch_inference.sql
│   └── 09_create_monitor.sql
├── test_agent/         # Testing scripts
└── TODO.md             # Detailed documentation
```

## Snowflake Objects

| Object | Type | Purpose |
|--------|------|---------|
| `BILLING_DATA` | Table | 365 days of cloud billing records |
| `COST_RECOMMENDATIONS` | Table | FinOps optimization recommendations |
| `DEMO_SEMANTIC_VIEW` | Semantic View | Text-to-SQL for cost analytics |
| `TEXT_SEARCH` | Cortex Search | Search FinOps recommendations |
| `DEMO_AGENT` | Cortex Agent | Multi-tool orchestration |
| `FORECAST_COST` | Procedure | Cost forecasting |
| `COST_MODEL_MONITOR` | Model Monitor | Track forecast accuracy |

## Key Features

- **Multi-cloud support**: AWS and Azure cost data
- **Time-series forecasting**: Predict costs with seasonality awareness
- **FinOps recommendations**: Rightsizing, reserved instances, storage optimization
- **ML Observability**: Monitor model drift and accuracy over time
- **Natural language interface**: Ask questions in plain English

See `TODO.md` for detailed implementation notes.
