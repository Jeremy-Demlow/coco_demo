# Setup Scripts

Execute these scripts **in order** to create the complete demo environment.

## Prerequisites

1. Snowflake account with SYSADMIN and ACCOUNTADMIN access
2. Database `WORKSHOP_DB` and schema `DEMO` created
3. Warehouse `WORKSHOP_WH` created
4. `transactions.csv` file in `../data/` folder

## Execution Order

```bash
# 1. Create table structure
snow sql -f 01_create_table.sql --connection myconnection

# 2. Upload data file to stage
snow stage copy ../data/transactions.csv @WORKSHOP_DB.DEMO.DATA_STAGE --connection myconnection

# 3. Load data from stage
snow sql -f 02_load_from_stage.sql --connection myconnection

# 4. Create Cortex Search Service
snow sql -f 03_create_search_service.sql --connection myconnection

# 5. Create Semantic View
snow sql -f 03b_create_semantic_view.sql --connection myconnection

# 6. Create Agent (with execution_environment!)
snow sql -f 04_create_agent.sql --connection myconnection

# 7. Grant permissions
snow sql -f 05_grants.sql --connection myconnection

# 8. Populate fraud labels
snow sql -f 06_populate_fraud_labels.sql --connection myconnection
```

## Key Configuration Notes

### Agent Warehouse Configuration

The agent requires `execution_environment` in `tool_resources`:

```yaml
tool_resources:
  Analyst1:
    semantic_view: "WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW"
    execution_environment:          # <-- REQUIRED
      type: warehouse
      warehouse: "WORKSHOP_WH"
      query_timeout: 299
```

**Without this, you'll get:** "The Analyst tool is missing an execution environment"

### Tool Descriptions

Follow best practices from the agent-optimization skill:
- Include "WHEN TO USE" and "WHEN NOT TO USE" sections
- Be specific about data coverage
- List key fields and metrics available

## Verification

After running all scripts, test the agent:

```bash
cd ../test_agent && python3 quick_test.py
```

Expected output: Agent responds with fraud analysis data.
