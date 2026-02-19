# Blackline Cortex Agent Demo

## Overview

A complete Cortex Agent demo for transaction fraud analysis, combining:
- **Cortex Analyst** (text-to-SQL) for structured transaction data
- **Cortex Search** for unstructured investigation notes
- **ML Predictions** for fraud risk scoring

---

## Phase 1: Agent with Analytics ✅ COMPLETE

### Directory Structure
```
coco_demo/
├── setup/                        # SQL scripts (run in order)
├── data/                         # Source data + data generator
├── model/                        # ML training scripts
├── test_agent/                   # Python test client
└── WORKSHOP_DB_DEMO_DEMO_AGENT/  # Agent workspace
```

### Snowflake Objects
| Object | Type | Status |
|--------|------|--------|
| `WORKSHOP_DB.DEMO.TRANSACTIONS` | Table | ✅ 100 rows |
| `WORKSHOP_DB.DEMO.TEXT_SEARCH` | Cortex Search Service | ✅ |
| `WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW` | Semantic View | ✅ |
| `WORKSHOP_DB.DEMO.DEMO_AGENT` | Cortex Agent | ✅ Working |

### Test Results
| Question | Result |
|----------|--------|
| Top 5 fraud transactions | ✅ Returns IDs, amounts, risk drivers |
| Fraud patterns | ✅ Geographic hotspots, channel risks |
| Executive summary | ✅ 23% fraud rate, recommendations |

---

## Phase 2: ML Fraud Prediction ✅ COMPLETE

### Goal
Add predictive capability: Intelligence (what happened) → Data Science (what may happen)

### Completed Tasks

#### 2.1 Validate Target Column ✅
- [x] Verified IS_FRAUD exists and has signal
- [x] Class distribution: 30% fraud rate (30/100) - good balance for demo
- [x] Reviewed example fraud cases - high amounts, suspicious keywords

#### 2.2 Feature Engineering ✅
Created 18 features:
- **Numeric**: AMOUNT_SCALED, AMOUNT_LOG
- **Boolean**: IS_FLAGGED
- **Categorical** (one-hot): TRANSACTION_TYPE (5), CHANNEL (4)
- **Text-derived** (5): NOTE_FLAGGED, NOTE_SUSPICIOUS, NOTE_DISPUTE, NOTE_BLOCKED, NOTE_INVESTIGATION

#### 2.3 Train Model ✅
- [x] Created training script: `notebooks/train_fraud_model.py`
- [x] Used machine-learning skill for best practices
- [x] Proper train/test split (80/20, stratified)
- [x] Trained GradientBoostingClassifier
- [x] **ROC-AUC: 0.810**
- [x] **Accuracy: 85%**
- [x] Feature importance analysis saved to `model_evaluation.png`

#### 2.4 Model Registry ✅
- [x] Registered to Snowflake Model Registry
- [x] Model: `WORKSHOP_DB.DEMO.FRAUD_DETECTION_MODEL` (v1)
- [x] Tested inference via `mv.run()` - working

#### 2.5 Agent Integration ✅ COMPLETE
- [x] Create stored procedure for inference (`PREDICT_FRAUD`)
- [x] Add prediction tool to agent (type: generic, name: FraudPredictor)
- [x] Update agent spec with tool_resources
- [x] Test: "What's the fraud risk for transaction X?" - Working!

### Model Artifacts
```
model/
├── fraud_model.py            # Training script (Pipeline + GridSearchCV + Experiment Tracking)
├── snowpark_session.py       # Snowflake connection helper
├── fraud_pipeline.pkl        # Local sklearn Pipeline backup (includes scaler/encoder)

data/
├── generate_data.py          # Generates 100k synthetic fraud transactions
├── transactions_100k.csv     # Generated data (if run locally)
```

**Note:** Feature names and scaler are embedded in the sklearn Pipeline. Confusion matrix and 
feature importance charts are logged to Snowflake Experiment Tracking, not stored locally.

### Model Performance
| Metric | Value |
|--------|-------|
| ROC-AUC | 0.810 |
| Accuracy | 85% |
| Precision (Fraud) | 80% |
| Recall (Fraud) | 67% |
| F1 (Fraud) | 73% |

---

## Phase 2.6: ML Monitoring ✅ COMPLETE

### Goal
Track model performance and detect drift over time using Snowflake ML Observability.

### Architecture
```
┌─────────────────┐     ┌─────────────────┐     ┌──────────────────────┐
│ Batch Inference │ ──▶ │ PREDICTION_LOG  │ ◀── │ FRAUD_MODEL_MONITOR  │
│ (08_batch...)   │     │ (100k rows)     │     │ - Drift (PSI)        │
└─────────────────┘     │ - 31 days data  │     │ - Accuracy metrics   │
                        └─────────────────┘     └──────────────────────┘
                               ▲
                        ┌──────┴──────┐
                        │ PREDICTION_ │
                        │ BASELINE    │ (first week snapshot)
                        └─────────────┘
```

### Completed Tasks
- [x] Create batch inference script (`setup/08_batch_inference.sql`)
- [x] Create PREDICTION_LOG table with 100k predictions
- [x] Create PREDICTION_BASELINE table for drift comparison
- [x] Create Model Monitor (`setup/09_create_monitor.sql`)
- [x] Configure drift detection (PSI, KL divergence)
- [x] Configure accuracy tracking (actual vs predicted)
- [x] Set refresh interval to 1 hour for demo

### Monitor Configuration
| Setting | Value |
|---------|-------|
| Refresh Interval | 1 hour |
| Aggregation Window | 1 day |
| Baseline | First week of predictions |
| Tracked Metrics | Drift (PSI), Accuracy, Precision, Recall, F1 |

### Viewing Metrics
- **Snowsight**: AI & ML → Models → FRAUD_DETECTION_MODEL → Monitors
- **SQL**: Query `FRAUD_MODEL_MONITOR!MODEL_MONITOR_*` functions

---

## Phase 3: Git Integration (Future)
- [ ] Push notebooks to Git repo
- [ ] Connect Snowsight to Git
- [ ] Run notebooks in Snowsight
- [ ] Full platform demo

---

## Quick Commands

```bash
# Test the agent (Phase 1)
cd test_agent && python3 quick_test.py

# Train ML model (Phase 2)
cd model && python fraud_model.py

# Generate synthetic data (if needed)
cd data && python generate_data.py
```

## Snowflake Objects Summary

| Object | Type | Purpose |
|--------|------|---------|
| `WORKSHOP_DB.DEMO.TRANSACTIONS` | Table | Source transaction data (100k rows) |
| `WORKSHOP_DB.DEMO.TEXT_SEARCH` | Cortex Search | Search notes text |
| `WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW` | Semantic View | Text-to-SQL for analytics |
| `WORKSHOP_DB.DEMO.DEMO_AGENT` | Cortex Agent | Multi-tool orchestration (3 tools) |
| `WORKSHOP_DB.DEMO.FRAUD_DETECTION_MODEL` | ML Model | Fraud prediction (LogisticRegression) |
| `WORKSHOP_DB.DEMO.PREDICT_FRAUD` | Procedure | Calls model for single transaction scoring |
| `WORKSHOP_DB.DEMO.PREDICTION_LOG` | Table | Batch predictions for monitoring |
| `WORKSHOP_DB.DEMO.PREDICTION_BASELINE` | Table | Baseline for drift detection |
| `WORKSHOP_DB.DEMO.FRAUD_MODEL_MONITOR` | Model Monitor | Tracks drift & accuracy |

## Key Learnings

### Agent Configuration
- `execution_environment` required in tool_resources
- WHEN TO USE / WHEN NOT TO USE in tool descriptions

### ML Best Practices (from machine-learning skill)
- Proper train/test splits (stratified for imbalanced data)
- SQL-compatible feature names (no hyphens/spaces)
- Model registry for production deployment
- Feature importance for explainability
