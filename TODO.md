# Cloud Cost Analytics Agent - Implementation TODO

## Overview

A Cortex Agent for cloud cost analytics and forecasting, combining:
- **Cortex Analyst** (text-to-SQL) for billing data queries
- **Cortex Search** for FinOps recommendations
- **ML Forecasting** for cost predictions

---

## Phase 1: Data Foundation ✅ COMPLETE

### Synthetic Data Generator
- [x] AWS services: EC2, S3, RDS, Lambda, EKS, CloudWatch, DynamoDB, ElastiCache
- [x] Azure services: VMs, Blob Storage, SQL Database, Functions, AKS, Cosmos DB
- [x] Realistic patterns: weekday/weekend, monthly seasonality, end-of-month spikes
- [x] Cost anomalies (3% probability)
- [x] Growth trends over time
- [x] Multiple accounts, departments, environments

### Files
```
data/
└── generate_data.py    # Generates 365 days × 15 accounts × services
```

---

## Phase 2: Analytics Layer ✅ COMPLETE

### Semantic View
- [x] Dimensions: date, cloud_provider, account, service, region, department, environment
- [x] Time dimensions: month, quarter, year
- [x] Measures: total_cost, average_daily_cost, usage, record_count
- [x] Verified queries for common patterns

### Search Service
- [x] 15 FinOps recommendations
- [x] Categories: Rightsizing, Reserved Instances, Storage, Spot, etc.
- [x] AWS and Azure coverage
- [x] Priority levels and potential savings

---

## Phase 3: ML Forecasting ✅ COMPLETE

### Model Architecture
- [x] XGBoost Regressor
- [x] Time-series features: day_of_week, day_of_month, month, quarter
- [x] Categorical features: cloud_provider, service, department
- [x] Usage quantity as feature

### Training Pipeline
- [x] Feature engineering in Snowpark
- [x] Train/test split (last 30 days for test)
- [x] Experiment tracking
- [x] Model Registry integration

### Monitoring
- [x] Batch inference for historical forecasts
- [x] Change tracking enabled
- [x] Model Monitor with regression metrics (MAE, RMSE, MAPE)
- [x] Baseline for drift detection

---

## Phase 4: Agent Integration ✅ COMPLETE

### Tools
| Tool | Type | Purpose |
|------|------|---------|
| Analyst1 | cortex_analyst | SQL queries on billing data |
| Search1 | cortex_search | FinOps recommendations |
| CostForecaster | generic | ML-based cost predictions |

### Procedures
- [x] `FORECAST_COST(service, department, days)` - Service-level forecast
- [x] `FORECAST_TOTAL_COST(days)` - Total cost forecast

---

## Phase 5: Documentation ✅ COMPLETE

- [x] README.md - Quick start guide
- [x] TODO.md - Detailed implementation notes
- [x] SQL scripts with comments
- [x] requirements.txt

---

## Snowflake Objects Summary

| Object | Type | Purpose |
|--------|------|---------|
| `WORKSHOP_DB.DEMO.BILLING_DATA` | Table | Cloud billing records |
| `WORKSHOP_DB.DEMO.COST_RECOMMENDATIONS` | Table | FinOps recommendations |
| `WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW` | Semantic View | Text-to-SQL |
| `WORKSHOP_DB.DEMO.TEXT_SEARCH` | Cortex Search | Recommendation search |
| `WORKSHOP_DB.DEMO.DEMO_AGENT` | Cortex Agent | Multi-tool agent |
| `WORKSHOP_DB.DEMO.FORECAST_COST` | Procedure | Cost forecasting |
| `WORKSHOP_DB.DEMO.FORECAST_LOG` | Table | Forecast history |
| `WORKSHOP_DB.DEMO.FORECAST_BASELINE` | Table | Baseline for monitoring |
| `WORKSHOP_DB.DEMO.COST_MODEL_MONITOR` | Model Monitor | Track accuracy |

---

## Quick Commands

```bash
# Generate data
cd data && python generate_data.py

# Upload to Snowflake
snow stage copy data/billing_data.csv @WORKSHOP_DB.DEMO.DATA_STAGE --connection myconnection

# Train model (optional)
cd model && python cost_forecast_model.py

# Test agent
cd test_agent && python quick_test.py
```

---

## Sample Agent Queries

### Cost Analytics
- "What was our total cloud spend last month?"
- "Show me the top 5 most expensive services by cloud provider"
- "Compare Engineering vs Data Science department costs"
- "What's the cost trend for EC2 over the past 6 months?"

### Recommendations
- "How can we reduce our AWS costs?"
- "Find rightsizing recommendations"
- "What reserved instance opportunities do we have?"
- "Show high-priority optimization recommendations"

### Forecasting
- "Forecast EC2 costs for Engineering for the next 30 days"
- "What will our total Azure spend be next month?"
- "Predict S3 storage costs for Data Science"

---

## Key Learnings

### Data Generation
- Realistic seasonality patterns are critical for meaningful forecasting
- Include anomalies to test model robustness
- Multiple dimensions enable rich analytics

### Model Monitoring
- Change tracking must be enabled BEFORE data insertion
- Regression metrics: MAE, RMSE, MAPE (not classification metrics)
- Baseline table essential for drift detection

### Agent Design
- Clear tool descriptions with WHEN TO USE / WHEN NOT TO USE
- Semantic view verified queries improve SQL accuracy
- Generic tools need explicit input_schema
