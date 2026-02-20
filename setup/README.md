# Setup Guide: Fraud Detection Agent

Complete setup instructions for deploying the Snowflake Intelligence fraud detection demo.

## Prerequisites

Before starting, ensure you have:

- [ ] Snowflake account with SYSADMIN and ACCOUNTADMIN access
- [ ] Snowflake CLI (`snow`) installed and configured
- [ ] Python 3.10+ with pip
- [ ] A key-pair for JWT authentication (for REST API testing)

### Create Key-Pair (if needed)
```bash
# Generate private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key.p8 -nocrypt

# Generate public key
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub

# Assign public key to your user (run in Snowflake)
ALTER USER your_username SET RSA_PUBLIC_KEY='MIIBIjAN...';
```

## Step-by-Step Setup

### Step 1: Create Database Objects
```bash
# Create warehouse, database, schema (if not exists)
snow sql -q "CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH WITH WAREHOUSE_SIZE='XSMALL'"
snow sql -q "CREATE DATABASE IF NOT EXISTS WORKSHOP_DB"
snow sql -q "CREATE SCHEMA IF NOT EXISTS WORKSHOP_DB.DEMO"
```

### Step 2: Create Table Structure
```bash
snow sql -f 01_create_table.sql
```
Creates `TRANSACTIONS` table with fraud detection columns.

### Step 3: Generate and Load Data
```bash
# Generate synthetic data
cd ../data && python generate_data.py

# Upload to stage
snow stage copy transactions_100k.csv @WORKSHOP_DB.DEMO.DATA_STAGE

# Load into table
cd ../setup && snow sql -f 02_load_from_stage.sql
```

### Step 4: Create Cortex Search Service
```bash
snow sql -f 03_create_search_service.sql
```
Creates `TEXT_SEARCH` service for semantic search on NOTES_TEXT.

### Step 5: Create Semantic View
```bash
snow sql -f 03b_create_semantic_view.sql
```
Creates `DEMO_SEMANTIC_VIEW` with dimensions, metrics, and synonyms.

### Step 6: Create the Agent
```bash
snow sql -f 04_create_agent.sql
```
Creates `DEMO_AGENT` with three tools:
- **Analyst1**: Text-to-SQL analytics
- **Search1**: Semantic search
- **FraudPredictor**: ML predictions

### Step 7: Grant Permissions
```bash
snow sql -f 05_grants.sql
```

### Step 8: Populate Fraud Labels
```bash
snow sql -f 06_populate_fraud_labels.sql
```
Adds realistic fraud patterns to the data.

### Step 9: Train ML Model
```bash
cd ../model && python fraud_model.py
```
Trains fraud detection model with:
- GridSearchCV hyperparameter tuning
- Experiment tracking in Snowflake
- Model Registry deployment

### Step 10: Create Prediction Procedure
```bash
cd ../setup && snow sql -f 07_create_prediction_procedure.sql
```
Creates `PREDICT_FRAUD` procedure for agent integration.

### Step 11: (Optional) Setup ML Monitoring
```bash
# Batch inference for monitoring baseline
snow sql -f 08_batch_inference.sql

# Create model monitor
snow sql -f 09_create_monitor.sql
```

## Verification

### Test the Agent
```bash
cd ../test_agent
python quick_test.py "What is the overall fraud rate?"
```

Expected output:
```
Question: What is the overall fraud rate?

============================================================
Duration: 3.2s
Tools: cortex_analyst_text_to_sql

Answer:
The overall fraud rate is **5.2%** across 100,000 transactions.
Key breakdown:
• Online channel: 8.2% fraud rate (highest)
• Wire transfers: 7.1% fraud rate
• In-branch: 1.2% fraud rate (lowest)
============================================================
```

### Test Each Tool

**Analyst (Text-to-SQL):**
```bash
python quick_test.py "Show me top 5 merchants by fraud count"
```

**Search (Semantic):**
```bash
python quick_test.py "Find notes mentioning unauthorized access"
```

**FraudPredictor (ML):**
```bash
python quick_test.py "What's the fraud risk for TXN_0000001?"
```

## Troubleshooting

### "The Analyst tool is missing an execution environment"
The agent requires `execution_environment` in tool_resources:
```yaml
tool_resources:
  Analyst1:
    semantic_view: "WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW"
    execution_environment:          # <-- REQUIRED
      type: warehouse
      warehouse: "WORKSHOP_WH"
```

### "Object does not exist" in Analyst queries
Verify semantic view was created:
```sql
DESCRIBE SEMANTIC VIEW WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW;
```

### Model not found for FraudPredictor
Ensure model is registered:
```sql
SHOW MODELS IN SCHEMA WORKSHOP_DB.DEMO;
```

### JWT authentication fails
1. Verify public key is assigned to user
2. Check key file path in `test_agent/quick_test.py`
3. Ensure key is not password-protected (or update code to handle password)

## Key Configuration Notes

### Agent Tool Descriptions
Each tool should have clear WHEN TO USE and WHEN NOT TO USE sections:
```yaml
description: |
  WHEN TO USE:
  - Transaction counts, totals, rates
  - Comparisons by channel, location
  
  WHEN NOT TO USE:
  - Searching text in notes (use Search1)
  - Predicting fraud risk (use FraudPredictor)
```

### Semantic View Best Practices
- Include synonyms for flexible querying
- Add clear comments on each dimension/metric
- Use consistent naming conventions

## Scripts Reference

| Script | Purpose | Dependencies |
|--------|---------|--------------|
| 01_create_table.sql | Create TRANSACTIONS table | None |
| 02_load_from_stage.sql | Load data from stage | 01, data file |
| 03_create_search_service.sql | Cortex Search on NOTES_TEXT | 01, 02 |
| 03b_create_semantic_view.sql | Semantic view for Analyst | 01, 02 |
| 04_create_agent.sql | Create agent with 3 tools | 03, 03b, 07 |
| 05_grants.sql | Grant permissions | 04 |
| 06_populate_fraud_labels.sql | Add fraud patterns | 02 |
| 07_create_prediction_procedure.sql | ML inference procedure | ML model |
| 08_batch_inference.sql | Batch predictions | 07 |
| 09_create_monitor.sql | ML monitoring | 08 |
