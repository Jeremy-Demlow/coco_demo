# Reconciliation 360 - dbt Project

A dbt project for the **Financial Reconciliation Management System** that creates comprehensive entity-level 360 views for reconciliation analysis, variance tracking, and compliance monitoring.

## Overview

This project transforms raw reconciliation data from PostgreSQL CDC replication into analytics-ready mart tables with a semantic model for natural language querying via Cortex Agent.

## Data Architecture

```
Source (DBAPI_REPLICA_DB.CUSTOMER_A_DATA)
    │
    ├── rec_periods
    ├── rec_assignments  
    ├── rec_reconciliations
    ├── rec_period_information
    ├── org_entities
    ├── users
    └── var_activity
    │
    ▼
Staging Layer (PUBLIC schema - views)
    │
    ├── stg_rec_periods
    ├── stg_rec_assignments
    ├── stg_rec_reconciliations
    ├── stg_rec_period_information
    ├── stg_org_entities
    ├── stg_users
    └── stg_var_activity
    │
    ▼
Intermediate Layer (PUBLIC schema - views)
    │
    ├── int_reconciliation_details
    └── int_variance_analysis
    │
    ▼
Marts Layer (PUBLIC_MARTS schema - tables)
    │
    ├── entity_360          ← Entity-level 360 view
    └── reconciliation_fact ← Detailed reconciliation records
```

## Mart Tables

### `entity_360`
Entity-level 360 view providing comprehensive reconciliation metrics per organization entity per period.

| Column | Description |
|--------|-------------|
| `entity_id`, `entity_code`, `entity_name` | Entity identifiers |
| `period_id`, `period_year`, `period_quarter`, `period_month_num` | Time dimensions |
| `total_assignments`, `active_assignments` | Assignment counts |
| `total_gl_balance`, `total_bank_balance`, `total_subledger_balance` | Balance summaries |
| `total_variance`, `total_absolute_variance`, `variance_count` | Variance metrics |
| `variance_risk_level` | Risk classification (High/Medium/Low/None) |

### `reconciliation_fact`
Detailed fact table for individual reconciliations with full context.

| Column | Description |
|--------|-------------|
| `reconciliation_id`, `assignment_id` | Record identifiers |
| `entity_name`, `entity_code`, `entity_parent_name` | Entity context |
| `account_combination`, `currency`, `segment1-5` | Account details |
| `balance_bank`, `balance_calculated`, `balance_subledger` | Balance values |
| `bank_calc_diff`, `bank_subledger_diff` | Calculated differences |
| `reconciliation_status` | Status (Reconciled/Minor Difference/Needs Review) |

## Semantic Model

Located at `models/semantic/reconciliation_360.yaml`, this semantic model enables natural language queries via Cortex Analyst/Agent.

**Sample questions it can answer:**
- "Which entities have high variance risk?"
- "What is the reconciliation status breakdown?"
- "Show me the monthly variance trend"
- "Which entities have the largest variances?"

## Configuration

### profiles.yml
```yaml
coco_demo:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: trb65519
      user: JDEMLOW
      role: ACCOUNTADMIN
      database: DBAPI_REPLICA_DB
      warehouse: SNOW_INTELLIGENCE_DEMO_WH
      schema: PUBLIC
      threads: 4
```

## Usage

### Run all models
```bash
dbt run --project-dir /coco_demo
```

### Run tests
```bash
dbt test --project-dir /coco_demo
```

### Compile only (validate SQL)
```bash
dbt compile --project-dir /coco_demo
```

### Run specific model
```bash
dbt run --select entity_360 --project-dir /coco_demo
```

## Exploration

See `explore_data_model.sql` for helpful queries to understand the data, including:
- Data overview and sample queries
- Risk distribution analysis
- Reconciliation status breakdown
- Trend analysis
- Data quality checks

## Project Structure

```
coco_demo/
├── dbt_project.yml
├── profiles.yml
├── README.md
├── explore_data_model.sql
├── models/
│   ├── staging/           # 7 staging views
│   ├── intermediate/      # 2 join views  
│   ├── marts/             # 2 mart tables
│   └── semantic/          # Semantic model YAML
├── tests/
├── macros/
├── seeds/
└── snapshots/
```

## Deployment

This project is deployed as a native Snowflake DBT PROJECT object for scheduled execution and monitoring.
