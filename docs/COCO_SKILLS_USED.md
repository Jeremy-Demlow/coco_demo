# Cortex Code (CoCo) Skills Used in This Demo

This document captures which CoCo skills were invoked during the development of this demo, when they were useful, and what they helped accomplish.

---

## Skills Overview

| Skill | When Invoked | Key Benefit |
|-------|--------------|-------------|
| `agent-optimization` | Creating agent spec | Proper tool descriptions with WHEN TO USE/NOT TO USE |
| `semantic-view-optimization` | Creating semantic view | Correct syntax, dimensions, metrics, synonyms |
| `machine-learning` | Training fraud model | Experiment tracking, model registry, best practices |

---

## 1. Agent Optimization Skill

### When to Invoke
```
/agent-optimization
```

Or CoCo will automatically suggest it when you mention creating/debugging a Cortex Agent.

### What It Helped With

**Problem:** Agent was routing questions to wrong tools. "Search for high fraud rates" went to Search instead of Analyst.

**Solution:** The skill provided a template for tool descriptions:

```yaml
description: |
  [Summary]

  DATA COVERAGE:
  - [What data is available]

  WHEN TO USE:
  - [Specific use case 1]
  - [Specific use case 2]

  WHEN NOT TO USE:
  - Do NOT use for [X] (use [other_tool] instead)
```

**Key Insight:** The "WHEN NOT TO USE" section is critical for routing. Be explicit about boundaries.

### Example from This Demo

Before (routing issues):
```yaml
description: "Searches transaction notes for investigation details"
```

After (clear routing):
```yaml
description: |
  Searches transaction NOTES_TEXT for investigation details and keywords.

  WHEN TO USE:
  - Finding transactions mentioning specific terms
  - Investigating why a transaction was flagged
  - Searching for patterns in notes

  WHEN NOT TO USE:
  - Do NOT use for counting transactions (use Analyst1)
  - Do NOT use for calculating rates (use Analyst1)
  - Do NOT use for predicting fraud (use FraudPredictor)
```

---

## 2. Semantic View Optimization Skill

### When to Invoke
```
/semantic-view-optimization
```

Or CoCo will automatically suggest it when you're working with semantic views.

### What It Helped With

**Problem:** Semantic view syntax errors, missing synonyms, unclear metric definitions.

**Solution:** The skill provided:
1. Correct DDL syntax for semantic views
2. Best practices for dimension definitions
3. How to add synonyms for flexible querying
4. Metric calculation patterns (COUNT_IF, ratios, etc.)

### Key Patterns Learned

**Dimensions with Synonyms:**
```sql
transactions.channel AS CHANNEL
    WITH SYNONYMS = ('payment channel', 'transaction channel')
    COMMENT = 'Channel used for the transaction'
```

**Rate Metrics:**
```sql
transactions.fraud_rate AS COUNT_IF(IS_FRAUD = TRUE) / NULLIF(COUNT(TRANSACTION_ID), 0)
    WITH SYNONYMS = ('fraud rate', 'fraud percentage')
    COMMENT = 'Percentage of confirmed fraudulent transactions'
```

**Key Insight:** The `NULLIF(..., 0)` prevents division by zero. Comments help the LLM understand the metric.

---

## 3. Machine Learning Skill

### When to Invoke
```
/machine-learning
```

Or CoCo will automatically suggest it when you're training models, registering to Model Registry, or setting up ML workflows.

### What It Helped With

**Problem:** Needed to train a fraud detection model, track experiments, and register to Snowflake Model Registry.

**Solution:** The skill provided:
1. sklearn Pipeline pattern for preprocessing + model
2. GridSearchCV for hyperparameter tuning
3. Snowflake Experiment Tracking integration
4. Model Registry deployment

### Code Pattern from the Skill

```python
from snowflake.ml.experiment import ExperimentTracking
from snowflake.ml.registry import Registry

# Experiment tracking
exp = ExperimentTracking(session=session)
exp.set_experiment("FRAUD_DETECTION")

with exp.start_run(run_name):
    exp.log_params({"model_type": "LogisticRegression", ...})
    exp.log_metrics({"accuracy": 0.85, "roc_auc": 0.81})
    exp.log_model(pipeline, model_name="FRAUD_DETECTION_MODEL")
    exp.log_artifact("confusion_matrix.png")

# Model Registry
registry = Registry(session=session)
model = registry.get_model("FRAUD_DETECTION_MODEL")
model.default = latest_version
```

**Key Insight:** Experiment tracking creates an audit trail. Model Registry enables versioning and inference via `MODEL!PREDICT()`.

---

## Skills NOT Used (But Available)

### data-governance
Would be useful for: Auditing who accessed what data, checking role permissions
```
/data-governance
```

### data-policy
Would be useful for: Creating masking policies, row access policies
```
/data-policy
```

### dynamic-tables
Would be useful for: Creating incremental data pipelines
```
/dynamic-tables
```

### integrations
Would be useful for: Setting up API integrations, notifications
```
/integrations
```

---

## Skill Invocation Tips

1. **Be Specific**: Tell CoCo exactly what you're trying to do. "Create a semantic view for fraud analytics" is better than "help with semantic view."

2. **Provide Context**: Share your table schema, sample data, or error messages.

3. **Iterate**: Skills work best when you iterate. Create → Test → Fix → Test.

4. **Read the Output**: Skills often provide checklists and best practices. Don't skip them.

---

## Example CoCo Session Flow

Here's how skills were invoked during the build:

```
User: I need to create a Cortex Agent for fraud detection with 
      text-to-SQL, search, and ML prediction tools.

CoCo: [Suggests invoking agent-optimization skill]
      Let me invoke the agent-optimization skill to help with this...

[Skill provides agent spec template and best practices]

User: Now I need to create the semantic view for the Analyst tool.

CoCo: [Suggests invoking semantic-view-optimization skill]
      Let me invoke the semantic-view-optimization skill...

[Skill provides semantic view DDL with dimensions/metrics]

User: I need to train the fraud detection model and register it.

CoCo: [Suggests invoking machine-learning skill]
      Let me invoke the machine-learning skill...

[Skill provides training script with experiment tracking]
```

---

## Reproducing This Demo

To reproduce this demo using CoCo skills:

1. **Start with BUILD_PROMPT.md** - Use the master prompt template
2. **Invoke `/agent-optimization`** when creating the agent
3. **Invoke `/semantic-view-optimization`** when creating the semantic view
4. **Invoke `/machine-learning`** when training the ML model
5. **Test and iterate** - Use skills to debug issues

The skills encode Snowflake best practices and save significant trial-and-error time.
