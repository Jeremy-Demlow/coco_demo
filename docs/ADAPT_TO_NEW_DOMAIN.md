# Adapting This Demo to a New Domain

This guide shows how to take the fraud detection demo structure and adapt it to completely different use cases. The architecture pattern (Analyst + Search + Custom Tool) works for many domains.

---

## Architecture Pattern

Every Cortex Agent demo follows this pattern:

```
┌─────────────────────────────────────────────────────────┐
│                    CORTEX AGENT                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │  Analyst    │  │   Search    │  │  Custom Tool    │ │
│  │ (Structured │  │ (Unstructured│  │ (Domain Logic)  │ │
│  │   Data)     │  │   Text)      │  │                 │ │
│  └──────┬──────┘  └──────┬──────┘  └────────┬────────┘ │
└─────────┼────────────────┼──────────────────┼──────────┘
          │                │                  │
          ▼                ▼                  ▼
   ┌────────────┐   ┌────────────┐   ┌──────────────────┐
   │ SEMANTIC   │   │  CORTEX    │   │ STORED PROCEDURE │
   │ VIEW       │   │  SEARCH    │   │ (or ML Model)    │
   └────────────┘   └────────────┘   └──────────────────┘
          │                │                  │
          └────────────────┼──────────────────┘
                           ▼
                    ┌────────────┐
                    │   TABLE    │
                    └────────────┘
```

---

## Domain Adaptation Examples

### Example 1: IT Support Tickets

| Original (Fraud) | Adaptation (Support) |
|-----------------|----------------------|
| **Table** | |
| TRANSACTIONS | SUPPORT_TICKETS |
| TRANSACTION_ID | TICKET_ID |
| CUSTOMER_ID | REQUESTER_ID |
| AMOUNT | PRIORITY (1-5) |
| TRANSACTION_TYPE | TICKET_CATEGORY |
| CHANNEL | SUBMISSION_CHANNEL |
| IS_FRAUD | IS_ESCALATED |
| NOTES_TEXT | TICKET_DESCRIPTION |
| **Metrics** | |
| fraud_rate | escalation_rate |
| total_amount | avg_resolution_time |
| avg_amount | tickets_per_day |
| **Custom Tool** | |
| FraudPredictor | EscalationPredictor |
| "Predict fraud risk" | "Predict if ticket will escalate" |

**Sample Questions:**
- "What's our average resolution time by category?"
- "Find tickets mentioning system outage"
- "Will ticket TKT_12345 likely escalate?"

---

### Example 2: Cloud Cost Management (FOCUS Billing)

| Original (Fraud) | Adaptation (Cost) |
|-----------------|-------------------|
| **Table** | |
| TRANSACTIONS | FOCUS_BILLING |
| TRANSACTION_ID | BILLING_ID |
| AMOUNT | BILLED_COST |
| TRANSACTION_TYPE | CHARGE_CATEGORY |
| CHANNEL | PROVIDER_NAME |
| MERCHANT | SERVICE_NAME |
| LOCATION | REGION |
| IS_FRAUD | IS_ANOMALY |
| NOTES_TEXT | CHARGE_DESCRIPTION |
| **Metrics** | |
| fraud_rate | cost_growth_rate |
| total_amount | total_cost |
| avg_amount | avg_daily_cost |
| **Custom Tool** | |
| FraudPredictor | CostForecaster |
| "Predict fraud" | "Forecast next month cost" |

**Sample Questions:**
- "What was our AWS spend last month by service?"
- "Find charges mentioning data transfer"
- "Forecast our compute costs for next quarter"

---

### Example 3: Healthcare Patient Records

| Original (Fraud) | Adaptation (Healthcare) |
|-----------------|------------------------|
| **Table** | |
| TRANSACTIONS | PATIENT_ENCOUNTERS |
| TRANSACTION_ID | ENCOUNTER_ID |
| CUSTOMER_ID | PATIENT_ID |
| AMOUNT | BILLED_AMOUNT |
| TRANSACTION_TYPE | ENCOUNTER_TYPE |
| CHANNEL | FACILITY |
| MERCHANT | PROVIDER_NAME |
| IS_FRAUD | IS_READMISSION |
| NOTES_TEXT | CLINICAL_NOTES |
| **Metrics** | |
| fraud_rate | readmission_rate |
| total_amount | total_charges |
| avg_amount | avg_length_of_stay |
| **Custom Tool** | |
| FraudPredictor | ReadmissionRiskPredictor |
| "Predict fraud" | "Predict readmission risk" |

**Sample Questions:**
- "What's the readmission rate by diagnosis category?"
- "Find patients with notes mentioning chest pain"
- "What's the readmission risk for patient P_12345?"

---

### Example 4: E-commerce Orders

| Original (Fraud) | Adaptation (E-commerce) |
|-----------------|------------------------|
| **Table** | |
| TRANSACTIONS | ORDERS |
| TRANSACTION_ID | ORDER_ID |
| CUSTOMER_ID | CUSTOMER_ID |
| AMOUNT | ORDER_TOTAL |
| TRANSACTION_TYPE | ORDER_TYPE |
| CHANNEL | SALES_CHANNEL |
| MERCHANT | PRODUCT_CATEGORY |
| LOCATION | SHIPPING_REGION |
| IS_FRAUD | IS_RETURNED |
| NOTES_TEXT | CUSTOMER_FEEDBACK |
| **Metrics** | |
| fraud_rate | return_rate |
| total_amount | total_revenue |
| avg_amount | avg_order_value |
| **Custom Tool** | |
| FraudPredictor | ReturnPredictor |
| "Predict fraud" | "Predict if order will be returned" |

**Sample Questions:**
- "What's our revenue by sales channel this month?"
- "Find orders with feedback mentioning damaged"
- "Will order ORD_56789 likely be returned?"

---

## Step-by-Step Adaptation Process

### Step 1: Map Your Domain to the Pattern

Create a mapping table like the examples above:
1. What is your primary entity? (transactions → your_entity)
2. What are your key dimensions? (type, channel, location → your_dimensions)
3. What text field needs search? (notes → your_text_field)
4. What's your binary outcome? (is_fraud → your_outcome)
5. What prediction/action makes sense? (fraud_prediction → your_prediction)

### Step 2: Adapt the Data Generator

Modify `data/generate_data.py`:
```python
# Change these constants
NUM_RECORDS = 100_000
OUTCOME_RATE = 0.05  # Your rate (fraud_rate, return_rate, etc.)

# Change reference data
CATEGORIES = ['Category1', 'Category2', ...]  # Your categories
CHANNELS = ['Channel1', 'Channel2', ...]      # Your channels

# Change the generate function
def generate_record(idx: int) -> dict:
    is_outcome = random.random() < OUTCOME_RATE
    
    return {
        'ID': f'PREFIX_{idx:07d}',
        'CATEGORY': random.choice(CATEGORIES),
        # ... your fields
        'IS_OUTCOME': is_outcome,
    }
```

### Step 3: Adapt the Table DDL

Modify `setup/01_create_table.sql`:
```sql
CREATE TABLE YOUR_TABLE (
    ID VARCHAR(20) PRIMARY KEY,
    -- Your dimensions
    CATEGORY VARCHAR(50),
    CHANNEL VARCHAR(50),
    -- Your measures
    AMOUNT NUMBER(12,2),
    -- Your outcome
    IS_OUTCOME BOOLEAN,
    -- Your text field
    TEXT_FIELD VARCHAR(16777216)
);
```

### Step 4: Adapt the Semantic View

Modify `setup/03b_create_semantic_view.sql`:
```sql
CREATE SEMANTIC VIEW YOUR_SEMANTIC_VIEW
    TABLES (
        your_table AS DATABASE.SCHEMA.YOUR_TABLE
    )
    DIMENSIONS (
        your_table.category AS CATEGORY
            WITH SYNONYMS = ('type', 'kind')
            COMMENT = 'The category of the record',
        -- ... more dimensions
    )
    METRICS (
        your_table.outcome_rate AS COUNT_IF(IS_OUTCOME=TRUE) / COUNT(*)
            WITH SYNONYMS = ('rate', 'percentage')
            COMMENT = 'Percentage of records with outcome',
        -- ... more metrics
    );
```

### Step 5: Adapt the Search Service

Modify `setup/03_create_search_service.sql`:
```sql
CREATE CORTEX SEARCH SERVICE YOUR_SEARCH
    ON TEXT_FIELD  -- Your text column
    WAREHOUSE = YOUR_WH
    TARGET_LAG = '1 hour'
AS (
    SELECT ID, CATEGORY, CHANNEL, TEXT_FIELD
    FROM YOUR_TABLE
);
```

### Step 6: Adapt the Custom Tool

Modify `setup/07_create_prediction_procedure.sql`:
```sql
CREATE PROCEDURE PREDICT_OUTCOME(RECORD_ID VARCHAR)
RETURNS VARIANT
AS
$$
    -- Your prediction logic
    -- Either ML model call or business rules
$$;
```

### Step 7: Adapt the Agent

Modify `setup/04_create_agent.sql`:
```sql
CREATE AGENT YOUR_AGENT
FROM SPECIFICATION
$$
instructions:
  orchestration: |
    You are a [YOUR DOMAIN] assistant for [YOUR AUDIENCE].
    -- Adapt the persona and style

tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: Analyst1
      description: |
        Analyzes [YOUR DATA] for metrics and patterns.
        WHEN TO USE: [Your analytics use cases]
        WHEN NOT TO USE: [Boundaries]

  - tool_spec:
      type: cortex_search
      name: Search1
      description: |
        Searches [YOUR TEXT FIELD] for [YOUR SEARCH USE CASES].
        WHEN TO USE: [Your search use cases]
        WHEN NOT TO USE: [Boundaries]

  - tool_spec:
      type: generic
      name: YourPredictor
      description: |
        [Your custom tool description]
        WHEN TO USE: [Your prediction use cases]
        WHEN NOT TO USE: [Boundaries]
$$;
```

---

## Checklist for Domain Adaptation

- [ ] Domain mapping table completed
- [ ] Data generator produces realistic data
- [ ] Table schema matches your domain
- [ ] Semantic view has appropriate dimensions/metrics
- [ ] Search service targets correct text field
- [ ] Custom tool implements domain-specific logic
- [ ] Agent instructions reflect domain persona
- [ ] Tool descriptions have clear boundaries
- [ ] Test questions cover all three tools
- [ ] Documentation updated for new domain

---

## Tips for Success

1. **Keep the Pattern**: The 3-tool structure (Analyst + Search + Custom) works well. Don't overcomplicate.

2. **Clear Tool Boundaries**: The most common issue is questions routing to the wrong tool. Make WHEN TO USE very specific.

3. **Domain-Specific Language**: Update synonyms in the semantic view to match how your users actually talk.

4. **Realistic Data**: Spend time on the data generator. Good synthetic data makes the demo convincing.

5. **Test Combined Questions**: The real value is when the agent uses multiple tools together. Test these thoroughly.
