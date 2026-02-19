# Cortex Agent Fraud Detection Demo

A complete Snowflake Cortex Agent demo combining text-to-SQL analytics, document search, and ML-powered fraud prediction.

## Quick Start

```bash
# 1. Setup Python environment
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2. Run SQL setup scripts (in Snowflake, in order)
# setup/01_create_table.sql through setup/09_create_monitor.sql

# 3. Train ML model (optional - model already registered)
cd model && python fraud_model.py

# 4. Test the agent
cd test_agent && python quick_test.py
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CORTEX AGENT                            │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
│  │  Analyst1   │  │  Search1    │  │   FraudPredictor     │ │
│  │ (text-SQL)  │  │ (doc search)│  │   (ML prediction)    │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬───────────┘ │
└─────────┼────────────────┼───────────────────┼──────────────┘
          │                │                   │
          ▼                ▼                   ▼
   ┌────────────┐   ┌────────────┐   ┌─────────────────────┐
   │ SEMANTIC   │   │ TEXT_SEARCH│   │ FRAUD_DETECTION_    │
   │ VIEW       │   │ SERVICE    │   │ MODEL (Registry)    │
   └────────────┘   └────────────┘   └─────────────────────┘
```

## Snowflake Objects

| Object | Type | Purpose |
|--------|------|---------|
| `TRANSACTIONS` | Table | 100k transaction records |
| `DEMO_SEMANTIC_VIEW` | Semantic View | Text-to-SQL analytics |
| `TEXT_SEARCH` | Cortex Search | Investigation notes search |
| `FRAUD_DETECTION_MODEL` | ML Model | Fraud prediction |
| `PREDICT_FRAUD` | Procedure | Single-transaction scoring |
| `FRAUD_MODEL_MONITOR` | Model Monitor | Drift & accuracy tracking |

## Sample Questions

- "Show me the top 10 highest value fraud transactions"
- "What patterns do you see in fraudulent activity?"
- "What's the fraud risk for transaction TXN_0001234?"
- "Search for any notes about wire transfer investigations"

## Project Structure

```
coco_demo/
├── data/           # Data generation scripts
├── model/          # ML training code
├── setup/          # SQL setup scripts (run in order)
├── test_agent/     # Python test clients
└── TODO.md         # Detailed project status
```

See `TODO.md` for detailed implementation notes and phase tracking.
