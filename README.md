# Snowflake Intelligence: Fraud Detection Demo

A complete demonstration of **Snowflake Intelligence powered by Cortex Agents** - combining natural language analytics, semantic search, and ML predictions into a unified AI assistant for fraud analysis.

## What is Snowflake Intelligence?

Snowflake Intelligence makes your data accessible through natural language. Instead of writing SQL queries or navigating dashboards, users simply ask questions and get answers. This demo showcases:

- **Cortex Agents**: Autonomous AI that orchestrates multiple tools to answer complex questions
- **Cortex Analyst**: Text-to-SQL for structured transaction data
- **Cortex Search**: Semantic search for unstructured investigation notes
- **ML Integration**: Real-time fraud prediction via Model Registry

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SNOWFLAKE INTELLIGENCE                           │
│                                                                         │
│  "What's the fraud risk for high-value online transactions?"            │
│                              │                                          │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      CORTEX AGENT                                │   │
│  │                   (Autonomous Orchestration)                     │   │
│  │                                                                  │   │
│  │   Understands intent → Selects tools → Synthesizes response     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
│          ┌───────────────────┼───────────────────┐                      │
│          ▼                   ▼                   ▼                      │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐            │
│  │   Analyst    │   │    Search    │   │  FraudPredictor  │            │
│  │  (Text→SQL)  │   │  (Semantic)  │   │  (ML Model)      │            │
│  └──────┬───────┘   └──────┬───────┘   └────────┬─────────┘            │
│         │                  │                    │                       │
│         ▼                  ▼                    ▼                       │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐            │
│  │  SEMANTIC    │   │ TEXT_SEARCH  │   │ FRAUD_DETECTION  │            │
│  │    VIEW      │   │   SERVICE    │   │     _MODEL       │            │
│  └──────────────┘   └──────────────┘   └──────────────────┘            │
│                              │                                          │
│                              ▼                                          │
│                    ┌─────────────────┐                                  │
│                    │  TRANSACTIONS   │  100,000 records                 │
│                    │     TABLE       │  with fraud labels               │
│                    └─────────────────┘                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Sample Conversations

### Analytics (Cortex Analyst)
```
User: "What's the fraud rate by channel?"

Agent: Online channel has the highest fraud rate at 8.2%, followed by 
       Mobile (4.1%) and ATM (3.5%). In-branch transactions show the 
       lowest fraud at 1.2%.
       
       Recommended action: Implement additional verification for 
       online transactions over $1,000.
```

### Search (Cortex Search)
```
User: "Find transactions mentioning velocity patterns"

Agent: Found 23 transactions with velocity-related notes:
       • TXN_0045123: "Multiple transactions in 5 minutes - velocity alert"
       • TXN_0067891: "Unusual transaction velocity from new device"
       • TXN_0089234: "Velocity check failed - 10 transactions in 1 hour"
```

### ML Prediction (FraudPredictor)
```
User: "What's the fraud risk for transaction TXN_0050000?"

Agent: **HIGH RISK** - Model predicts fraud with 87% confidence.
       
       Risk factors:
       • Channel: Online (highest fraud rate)
       • Amount: $4,523 (above 95th percentile)
       • Merchant: International_Vendor (flagged category)
       
       Actual status: Confirmed fraud ✓
```

## Quick Start

```bash
# 1. Clone and setup environment
git clone <repo-url> && cd coco_demo
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2. Create Snowflake infrastructure (FIRST!)
cd setup
snow sql -f 00_prerequisites.sql   # Creates WH, DB, Schema, Stage

# 3. Create table and generate data
snow sql -f 01_create_table.sql
cd ../data && python generate_data.py   # Generates transactions_100k.csv

# 4. Upload and load data
snow stage copy transactions_100k.csv @WORKSHOP_DB.DEMO.DATA_STAGE
cd ../setup
snow sql -f 02_load_from_stage.sql

# 5. Create AI services
snow sql -f 03_create_search_service.sql   # Cortex Search
snow sql -f 03b_create_semantic_view.sql   # Semantic View

# 6. Add fraud patterns to data
snow sql -f 06_populate_fraud_labels.sql

# 7. Train ML model (REQUIRED before agent!)
cd ../model && python fraud_model.py

# 8. Create prediction procedure (MUST come after model)
cd ../setup
snow sql -f 07_create_prediction_procedure.sql

# 9. Create agent (MUST come after procedure)
snow sql -f 04_create_agent.sql
snow sql -f 05_grants.sql

# 10. (Optional) Setup ML monitoring
snow sql -f 08_batch_inference.sql
snow sql -f 09_create_monitor.sql

# 11. Test the agent
cd ../test_agent && python quick_test.py "What's the overall fraud rate?"

# To reset and rebuild from scratch:
cd ../setup && snow sql -f 99_teardown.sql
```

> **Note**: See `setup/README.md` for detailed instructions, prerequisites, and troubleshooting.

## Project Structure

```
coco_demo/
├── README.md                      # This file
├── requirements.txt               # Python dependencies
│
├── data/
│   └── generate_data.py           # Synthetic fraud data generator
│
├── model/
│   └── fraud_model.py             # ML training with experiment tracking
│
├── setup/                         # SQL scripts (execute in order)
│   ├── README.md                  # Detailed setup guide
│   ├── 01_create_table.sql        # TRANSACTIONS table
│   ├── 02_load_from_stage.sql     # Load data from stage
│   ├── 03_create_search_service.sql   # Cortex Search
│   ├── 03b_create_semantic_view.sql   # Semantic view for Analyst
│   ├── 04_create_agent.sql        # Cortex Agent with 3 tools
│   ├── 05_grants.sql              # Permissions
│   ├── 06_populate_fraud_labels.sql   # Add fraud labels
│   ├── 07_create_prediction_procedure.sql  # ML inference procedure
│   ├── 08_batch_inference.sql     # Batch scoring for monitoring
│   └── 09_create_monitor.sql      # ML Observability monitor
│
├── test_agent/
│   ├── agent_client.py            # JWT REST API client
│   ├── quick_test.py              # CLI test tool
│   └── test_config.yaml           # Configuration template
│
└── docs/
    ├── BUILD_PROMPT.md            # How to build this from scratch
    ├── ADAPT_TO_NEW_DOMAIN.md     # How to adapt to your use case
    └── COCO_SKILLS_USED.md        # CoCo skills reference
```

## Snowflake Objects Created

| Object | Type | Purpose |
|--------|------|---------|
| `TRANSACTIONS` | Table | 100k transaction records with fraud labels |
| `DEMO_SEMANTIC_VIEW` | Semantic View | Enables text-to-SQL analytics |
| `TEXT_SEARCH` | Cortex Search Service | Semantic search on NOTES_TEXT |
| `DEMO_AGENT` | Cortex Agent | Orchestrates all 3 tools |
| `FRAUD_DETECTION_MODEL` | ML Model | Fraud prediction in Model Registry |
| `PREDICT_FRAUD` | Procedure | Calls ML model for single transactions |
| `PREDICTION_LOG` | Table | Batch predictions for monitoring |
| `FRAUD_MODEL_MONITOR` | Model Monitor | Tracks drift and accuracy |

## Key Features Demonstrated

### 1. Cortex Agents (Autonomous AI)
- Natural language understanding
- Automatic tool selection based on question intent
- Multi-tool orchestration for complex queries
- Response synthesis and formatting

### 2. Cortex Analyst (Text-to-SQL)
- Semantic view with dimensions and metrics
- Synonyms for flexible querying ("fraud rate" = "fraud percentage")
- Automatic SQL generation and execution

### 3. Cortex Search (Semantic Search)
- Full-text search on unstructured notes
- Semantic matching (not just keyword)
- Returns relevant context for investigations

### 4. ML Integration
- Model Registry for versioned models
- Experiment tracking for training runs
- Stored procedure for real-time inference
- Model Monitor for drift detection

## Built With Cortex Code (CoCo)

This demo was built using Cortex Code, Snowflake's AI-powered CLI. Key skills used:

| Skill | Purpose |
|-------|---------|
| `agent-optimization` | Agent spec with proper tool descriptions |
| `semantic-view-optimization` | Semantic view with dimensions/metrics |
| `machine-learning` | ML training, registry, monitoring |

See `docs/COCO_SKILLS_USED.md` for detailed usage examples.

---

**Next Steps**: See `setup/README.md` for detailed setup instructions, or `docs/BUILD_PROMPT.md` to learn how to build similar demos for your own use cases.
