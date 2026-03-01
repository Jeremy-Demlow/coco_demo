# COCO Demo - Entity 360 dbt Project

A comprehensive dbt project for the **Reconciliation Management System** that creates an Entity 360 view with semantic layer support for Cortex Analyst integration.

## 📁 Project Structure

```
coco_demo/
├── dbt_project.yml              # dbt project configuration
├── profiles.yml                 # Snowflake connection (COCO_LIVE_DB, ACCOUNTADMIN)
├── packages.yml                 # dbt packages (dbt_semantic_view)
├── models/
│   ├── staging/                 # Source data cleaning & standardization
│   │   ├── schema.yml           # Source definitions & model docs
│   │   ├── stg_org_entities.sql
│   │   ├── stg_rec_assignments.sql
│   │   ├── stg_rec_periods.sql
│   │   ├── stg_rec_period_information.sql
│   │   ├── stg_rec_reconciliations.sql
│   │   ├── stg_rec_items.sql
│   │   ├── stg_users.sql
│   │   ├── stg_comment_details.sql
│   │   └── stg_var_activity.sql
│   ├── intermediate/            # Business logic transformations
│   │   ├── schema.yml
│   │   ├── int_assignment_period_balances.sql
│   │   └── int_variance_analysis.sql
│   └── marts/                   # Final business-ready models
│       ├── schema.yml
│       ├── mart_entity_360.sql
│       ├── mart_variance_summary.sql
│       └── semantic_entity_360.sql  # Snowflake Semantic View
├── macros/
│   └── generate_schema_name.sql
├── semantic_models/             # Legacy YAML semantic model (optional)
│   └── entity_360_semantic.yaml
├── entity_360_dashboard.ipynb   # Plotly visualization notebook
└── conversation_prompts.md      # Original conversation prompts
```

## 🗄️ Data Model Overview

### Source Database: `COCO_LIVE_DB.CUSTOMER_A_DATA`

The source system is a **Financial Reconciliation Management System** with ~5.5M rows across 14 tables:

| Category | Key Tables | Row Count |
|----------|------------|-----------|
| **Organization** | `org_entities` | 650 |
| **Periods** | `rec_periods` | 48 |
| **Assignments** | `rec_assignments` | 32,500 |
| **Reconciliations** | `rec_reconciliations` | 652,500 |
| **Period Info** | `rec_period_information` | 1.76M |
| **Items** | `rec_items` | 2.97M |
| **Variance** | `var_activity` | 183,125 |
| **Users** | `users` | 10,254 |
| **Comments** | `comment_details` | 25,873 |

### Data Flow

```
Sources (CUSTOMER_A_DATA)
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  STAGING LAYER (stg_*)                              │
│  - Clean & standardize source data                  │
│  - Filter deleted records                           │
│  - Rename columns for clarity                       │
└─────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  INTERMEDIATE LAYER (int_*)                         │
│  - Join related entities                            │
│  - Calculate derived metrics                        │
│  - Apply business logic (variance severity, etc.)   │
└─────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  MARTS LAYER (mart_*)                               │
│  - Entity 360 comprehensive view                    │
│  - Variance summary by period                       │
│  - Health scoring & KPIs                            │
└─────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  SEMANTIC LAYER                                     │
│  - Snowflake Semantic View for Cortex Analyst       │
│  - Natural language query support                   │
└─────────────────────────────────────────────────────┘
```

## 🎯 Key Models

### `mart_entity_360`
Comprehensive 360-degree view of each organizational entity:

| Metric Category | Fields |
|-----------------|--------|
| **Identity** | entity_id, entity_code, entity_name, entity_type |
| **Hierarchy** | parent_id, parent_name, hierarchy_depth, lineage |
| **Assignment Metrics** | total_assignments, periods_with_activity |
| **Balance Metrics** | total_gl_balance, total_bank_balance, total_subledger_balance |
| **Reconciliation Status** | reconciled_count, high_variance_count, reconciliation_completion_pct |
| **Variance Metrics** | total_variance_amount, critical_variance_count, high_severity_count |
| **Current Period** | current_period_gl_balance, current_reconciled_count |
| **Health Score** | entity_health_status (Critical, At Risk, Healthy, Needs Attention, No Activity) |

### `mart_variance_summary`
Period-by-period variance analysis:
- Variance totals and averages by entity/period
- Severity counts (critical, high, medium, low)
- Period risk level classification

### `semantic_entity_360`
Snowflake Semantic View enabling natural language queries via Cortex Analyst:
- Facts, dimensions, and metrics defined
- Synonyms for natural language understanding
- Relationships between entities and variance tables

## 🚀 Getting Started

### Prerequisites
- Snowflake account with access to `COCO_LIVE_DB`
- dbt installed (or use Snowflake's native dbt)
- `ACCOUNTADMIN` role (or appropriate privileges)

### Installation

```bash
# Install dependencies
dbt deps --project-dir /coco_demo

# Run all models
dbt build --project-dir /coco_demo

# Run specific model
dbt run --select mart_entity_360 --project-dir /coco_demo
```

### Verify Installation

```sql
-- Check semantic view
SHOW SEMANTIC VIEWS IN COCO_LIVE_DB.PUBLIC;

-- Query entity health distribution
SELECT entity_health_status, COUNT(*) 
FROM COCO_LIVE_DB.PUBLIC.MART_ENTITY_360 
GROUP BY 1;
```

## 📊 Dashboard

The `entity_360_dashboard.ipynb` notebook provides interactive Plotly visualizations:

1. **Entity Health Distribution** - Donut chart of health status breakdown
2. **Variance Severity Analysis** - Stacked bar by health status
3. **Variance Trends** - Period-over-period analysis
4. **At-Risk Entity Scatter** - Completion rate vs variance
5. **Completion Distribution** - Histogram of completion rates
6. **KPI Indicators** - Key metrics at a glance

---

## 🔮 Recommended Next Steps

### 1. **Add Incremental Models**
Convert high-volume models to incremental for better performance:

```sql
-- Example: Convert mart_entity_360 to incremental
{{ config(
    materialized='incremental',
    unique_key='entity_id',
    incremental_strategy='merge'
) }}
```

**Priority Tables:**
- `stg_rec_period_information` (1.76M rows)
- `stg_rec_items` (2.97M rows)
- `stg_var_activity` (183K rows)

### 2. **Add Data Quality Tests**

```yaml
# models/staging/schema.yml
models:
  - name: stg_rec_assignments
    columns:
      - name: assignment_id
        tests:
          - unique
          - not_null
      - name: entity_id
        tests:
          - not_null
          - relationships:
              to: ref('stg_org_entities')
              field: entity_id
```

**Recommended Tests:**
- Referential integrity between tables
- Accepted values for status fields
- Row count thresholds
- Freshness checks on source data

### 3. **Add Source Freshness Checks**

```yaml
# models/staging/schema.yml
sources:
  - name: coco_live
    freshness:
      warn_after: {count: 24, period: hour}
      error_after: {count: 48, period: hour}
    loaded_at_field: db_update_date
```

### 4. **Create Additional Marts**

| Model | Purpose |
|-------|---------|
| `mart_user_workload` | User assignment distribution & productivity |
| `mart_period_close_status` | Period-level close tracking dashboard |
| `mart_reconciliation_aging` | Aging analysis of open reconciliations |
| `mart_currency_impact` | FX impact analysis across entities |
| `mart_certification_tracker` | Certification workflow status |

### 5. **Add Exposures for Downstream Dependencies**

```yaml
# models/marts/exposures.yml
exposures:
  - name: entity_360_dashboard
    type: dashboard
    maturity: high
    url: /coco_demo/entity_360_dashboard.ipynb
    depends_on:
      - ref('mart_entity_360')
      - ref('mart_variance_summary')
    owner:
      name: Data Team
      email: data@company.com

  - name: cortex_analyst_semantic
    type: ml
    maturity: high
    description: Semantic view for Cortex Analyst natural language queries
    depends_on:
      - ref('semantic_entity_360')
```

### 6. **Add Documentation**

```yaml
# models/marts/schema.yml - Enhanced docs
models:
  - name: mart_entity_360
    description: '{{ doc("mart_entity_360") }}'
    
# models/docs/mart_entity_360.md
{% docs mart_entity_360 %}
## Entity 360 View

This model provides a comprehensive view of each organizational entity...

### Business Logic
- **Health Status Calculation**: Based on critical variance count and reconciliation completion
- **Variance Aggregation**: Summed across all periods and assignments

### Usage Examples
```sql
-- Find entities needing attention
SELECT * FROM mart_entity_360 
WHERE entity_health_status = 'Critical';
```
{% enddocs %}
```

### 7. **Performance Optimizations**

```sql
-- Add clustering to large tables
{{ config(
    materialized='table',
    cluster_by=['entity_id', 'period_id']
) }}

-- Consider dynamic tables for real-time updates
{{ config(
    materialized='dynamic_table',
    target_lag='1 hour'
) }}
```

### 8. **Add Metrics Layer (dbt Semantic Layer)**

Consider adding dbt metrics for standardized KPI definitions:

```yaml
metrics:
  - name: reconciliation_completion_rate
    label: Reconciliation Completion Rate
    type: ratio
    numerator: reconciled_count
    denominator: total_assignments
    
  - name: critical_variance_ratio
    label: Critical Variance Ratio
    type: ratio
    numerator: critical_variance_count
    denominator: total_variance_records
```

### 9. **CI/CD Integration**

Add GitHub Actions or similar for:
- Automated testing on PR
- Scheduled dbt runs
- Data quality alerts
- Documentation deployment

### 10. **Cortex Agent Integration**

With the semantic view in place, create a Cortex Agent:

```sql
CREATE CORTEX AGENT reconciliation_agent
  SEMANTIC_VIEW = 'COCO_LIVE_DB.PUBLIC.SEMANTIC_ENTITY_360'
  COMMENT = 'Agent for querying reconciliation entity data';
```

---

## 📋 Model Lineage

```
stg_org_entities ─────────────────────────────────────┐
stg_rec_assignments ──┬─► int_assignment_period_balances ─┬─► mart_entity_360 ─┐
stg_rec_periods ──────┤                                   │                    │
stg_rec_period_info ──┘                                   │                    ├─► semantic_entity_360
                                                          │                    │
stg_var_activity ─────┬─► int_variance_analysis ──────────┴─► mart_variance_summary
stg_rec_periods ──────┘
```

---

## 🔧 Configuration

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
      database: COCO_LIVE_DB
      warehouse: SNOW_INTELLIGENCE_DEMO_WH
      schema: PUBLIC
      threads: 4
```

### packages.yml
```yaml
packages:
  - package: Snowflake-Labs/dbt_semantic_view
    version: 1.0.3
```

---

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Snowflake Semantic Views](https://docs.snowflake.com/en/user-guide/views-semantic)
- [dbt_semantic_view Package](https://github.com/Snowflake-Labs/dbt_semantic_view)
- [Cortex Analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [Plotly in Snowflake Notebooks](https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks-visualize-data)

---

## 🖥️ Streamlit Dashboard: Reconciliation 360

A professional multi-page dashboard for visualizing reconciliation data.

### Dashboard Pages

| Page | Description |
|------|-------------|
| **🏠 Executive Summary** | KPIs, health distribution donut chart, top at-risk entities |
| **🏢 Entity Explorer** | Search, filter, sort entities with detailed metric cards |
| **📊 Variance Analysis** | Period trends, severity breakdowns, detailed variance table |
| **🤖 ML Insights** | Anomaly detection results, Z-score distributions |

### Files

```
coco_demo/streamlit/
├── streamlit_app.py     # Main application (438 lines)
├── environment.yml      # Conda dependencies
└── deploy.sql           # Deployment script
```

### Deployment

**Option 1: Via Snowsight UI**
1. Navigate to Data > Databases > COCO_LIVE_DB > PUBLIC > Stages
2. Create stage `RECONCILIATION_360_STAGE`
3. Upload `streamlit_app.py` and `environment.yml`
4. Create Streamlit from stage

**Option 2: Via SQL**
```sql
-- Run the deploy.sql script
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE STREAMLIT COCO_LIVE_DB.PUBLIC.RECONCILIATION_360
    ROOT_LOCATION = '@COCO_LIVE_DB.PUBLIC.RECONCILIATION_360_STAGE'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = 'SNOW_INTELLIGENCE_DEMO_WH'
    TITLE = 'Reconciliation 360';
```

**Option 3: Via SnowCLI**
```bash
snow streamlit deploy --database COCO_LIVE_DB --schema PUBLIC
```

### Features

- **Native Snowflake Integration**: Uses `get_active_session()` for seamless auth
- **Altair Charts**: Professional visualizations with interactive tooltips
- **Material Icons**: Modern UI with `:material/icon_name:` syntax
- **Cached Data**: 5-minute TTL for optimal performance
- **Responsive Design**: Wide layout with column-based grids

---

## 🤖 Machine Learning Pipeline

### Anomaly Detection for Variance Analysis

The project includes a complete ML pipeline for detecting anomalous variances in reconciliations.

#### Feature Store: `mart_anomaly_features`

Engineered features for ML models:

| Feature Category | Features |
|-----------------|----------|
| **Balance Metrics** | balance_gl, balance_bank, gl_bank_variance, period_abs_variance |
| **Historical Stats** | hist_avg_gl_balance, hist_stddev_gl_balance, hist_avg_variance |
| **Z-Scores** | gl_balance_zscore, variance_zscore, abs_variance_zscore |
| **Derived** | variance_to_gl_ratio, gl_period_change |
| **Entity Context** | entity_type, ownership, hierarchy_depth |
| **Label** | is_anomaly_label (1 if Critical/High severity) |

#### ML Notebook: `anomaly_detection_ml.ipynb`

**Pipeline Components:**

1. **EDA** - Feature distributions, correlations, class balance
2. **Time-Based Split** - 80/20 split on time to prevent data leakage
3. **Models Trained:**
   - Isolation Forest (unsupervised)
   - XGBoost Classifier (supervised with GridSearchCV)
   - One-Class SVM (semi-supervised)
   - XGBoost V2 (extended HPO with RandomizedSearchCV)

4. **Experiment Tracking** - Snowflake ML Experiments with logged:
   - Hyperparameters
   - Metrics (precision, recall, F1, ROC AUC)
   - Model artifacts

5. **Model Registry** - Version management with:
   - Multiple versions for comparison
   - Automatic promotion based on F1 improvement threshold
   - Default version setting

#### Key ML Best Practices Implemented:

```
✅ Time-based train/test split (no data leakage)
✅ Cross-validation with TimeSeriesSplit
✅ Hyperparameter tuning (Grid + Randomized Search)
✅ Multiple algorithm comparison
✅ Experiment tracking with metrics
✅ Model versioning and registry
✅ Automatic best model promotion
✅ Feature store pattern (dbt view)
```

#### Run the ML Pipeline:

```python
# In Snowflake Notebook
# 1. Open anomaly_detection_ml.ipynb
# 2. Run all cells
# 3. Check experiment: COCO_LIVE_DB.PUBLIC.variance_anomaly_detection
# 4. Check registry: COCO_LIVE_DB.PUBLIC.variance_anomaly_detector
```
