# Build Prompt: Creating a Cortex Agent Demo from Scratch

This document provides a reusable prompt template for building Snowflake Intelligence demos using Cortex Agents. Use this with Cortex Code (CoCo) to generate similar demos for any domain.

---

## The Master Prompt

Copy and customize this prompt to build your own Cortex Agent demo:

```
I want to build a Snowflake Intelligence demo using Cortex Agents that combines:
1. Cortex Analyst (text-to-SQL for structured data analysis)
2. Cortex Search (semantic search for unstructured text)
3. Custom Tool (stored procedure for domain-specific capability)

## My Domain: [YOUR DOMAIN HERE]

### Data Description
- Primary entity: [e.g., transactions, tickets, invoices, patients]
- Record count: [e.g., 100,000 synthetic records]
- Time range: [e.g., last 90 days]

### Key Dimensions
- [e.g., transaction_type, channel, location, merchant]
- [e.g., ticket_priority, category, assigned_team]
- [e.g., department, cost_center, service_name]

### Key Metrics
- [e.g., fraud_rate, total_amount, average_value]
- [e.g., resolution_time, escalation_rate, satisfaction_score]
- [e.g., monthly_cost, utilization_rate, budget_variance]

### Unstructured Text Field
- Field name: [e.g., NOTES_TEXT, DESCRIPTION, COMMENTS]
- Contains: [e.g., investigation notes, customer feedback, incident details]
- Search use cases: [e.g., find mentions of "unauthorized", search for escalation reasons]

### Custom Tool Capability
- Tool name: [e.g., FraudPredictor, CostForecaster, EscalationClassifier]
- What it does: [e.g., predicts fraud probability, forecasts next month cost, classifies ticket priority]
- Implementation: [stored procedure calling ML model / calculation logic]

## Deliverables I Need

1. **Data Generator** (Python)
   - Synthetic data with realistic patterns
   - Proper distribution of categories
   - Text field with searchable content

2. **Table DDL** (SQL)
   - Appropriate column types
   - Comments on each column
   - Primary key defined

3. **Semantic View** (SQL)
   - Dimensions with synonyms
   - Metrics with clear calculations
   - Good comments for LLM understanding

4. **Cortex Search Service** (SQL)
   - On the unstructured text field
   - Include relevant metadata columns

5. **Agent Definition** (SQL)
   - 3 tools with WHEN TO USE / WHEN NOT TO USE
   - Clear orchestration instructions
   - Appropriate budget settings

6. **Custom Tool Procedure** (SQL)
   - Input parameters
   - Return format (VARIANT with structured response)
   - Integration with agent

7. **Test Client** (Python)
   - JWT authentication
   - SSE streaming parser
   - Formatted output

## Sample Questions the Agent Should Answer

Analytics:
- "[e.g., What's the fraud rate by channel?]"
- "[e.g., Show top 10 transactions by amount]"

Search:
- "[e.g., Find transactions mentioning unauthorized access]"
- "[e.g., Search for notes about velocity patterns]"

Custom Tool:
- "[e.g., What's the fraud risk for transaction X?]"
- "[e.g., Predict fraud for TXN_0001234]"

Combined:
- "[e.g., Give me an executive summary of fraud status with recommendations]"
```

---

## Example: Fraud Detection Domain

Here's how we filled out this template for the fraud detection demo:

### Domain: Financial Transaction Fraud Analysis

**Data Description:**
- Primary entity: Financial transactions
- Record count: 100,000 synthetic records
- Time range: Last 90 days

**Key Dimensions:**
- transaction_type (Purchase, Transfer, Wire, Withdrawal, Deposit)
- channel (Online, Mobile, ATM, Branch, Phone)
- location (major US cities + "Foreign")
- merchant (retail brands + "Unknown", "International_Vendor")

**Key Metrics:**
- fraud_rate (COUNT_IF(IS_FRAUD=TRUE) / COUNT(*))
- flagged_rate (COUNT_IF(IS_FLAGGED=TRUE) / COUNT(*))
- total_amount (SUM(AMOUNT))
- avg_amount (AVG(AMOUNT))

**Unstructured Text Field:**
- Field: NOTES_TEXT
- Contains: Investigation notes, customer complaints, system alerts
- Search cases: "unauthorized", "velocity", "suspicious IP", "chargeback"

**Custom Tool:**
- Name: FraudPredictor
- Does: Calls ML model to predict fraud probability
- Returns: risk_assessment (HIGH/ELEVATED/NORMAL) + explanation

---

## CoCo Skills to Invoke

When building with Cortex Code, invoke these skills at the right time:

### 1. For Semantic View Creation
```
/semantic-view-optimization
```
Use when: Creating or debugging the semantic view
Helps with: Proper dimension/metric definitions, synonyms, avoiding common errors

### 2. For Agent Configuration
```
/agent-optimization
```
Use when: Writing the agent specification
Helps with: Tool descriptions, orchestration instructions, budget settings

### 3. For ML Integration
```
/machine-learning
```
Use when: Training models, experiment tracking, model registry
Helps with: Best practices for sklearn pipelines, Snowflake ML integration

---

## Step-by-Step Build Process

### Phase 1: Data Foundation
1. Design your table schema based on domain requirements
2. Write a Python data generator with realistic patterns
3. Create the table DDL with proper types and comments
4. Generate data and load into Snowflake

### Phase 2: Search Capability
1. Identify which text field needs semantic search
2. Create Cortex Search service on that field
3. Include relevant metadata columns for filtering
4. Test with sample search queries

### Phase 3: Analytics Capability
1. Invoke `/semantic-view-optimization`
2. Define dimensions (categorical/date fields)
3. Define metrics (aggregations, rates, calculations)
4. Add synonyms for flexible querying
5. Test with sample analytics questions

### Phase 4: Custom Tool
1. Design the tool's input/output contract
2. If ML-based: train model, register to Model Registry
3. Create stored procedure with VARIANT return type
4. Test procedure independently

### Phase 5: Agent Assembly
1. Invoke `/agent-optimization`
2. Write orchestration instructions (persona, style)
3. Define each tool with clear boundaries
4. Configure tool_resources with execution_environment
5. Test with questions for each tool + combined

### Phase 6: Testing & Refinement
1. Create Python test client with JWT auth
2. Test each tool individually
3. Test combined questions
4. Refine tool descriptions based on routing issues

---

## Common Patterns

### Tool Description Template
```yaml
description: |
  [One-line summary of what this tool does]

  DATA COVERAGE:
  - [What data it has access to]
  - [Key fields available]

  WHEN TO USE:
  - [Specific use case 1]
  - [Specific use case 2]
  - [Specific use case 3]

  WHEN NOT TO USE:
  - Do NOT use for [task] (use [other_tool] instead)
  - Do NOT use for [task] (use [other_tool] instead)
```

### Orchestration Instructions Template
```yaml
instructions:
  orchestration: |
    You are a [ROLE] assistant. Your audience is [TARGET_AUDIENCE].

    RESPONSE STYLE:
    - [Style guideline 1]
    - [Style guideline 2]

    TOOL SELECTION:
    - Use [Tool1] for: [use cases]
    - Use [Tool2] for: [use cases]
    - Use [Tool3] for: [use cases]

    IMPORTANT RULES:
    - [Domain-specific rule 1]
    - [Domain-specific rule 2]
```

---

## Checklist Before Demo

- [ ] All SQL scripts execute without errors
- [ ] Data is loaded (verify row counts)
- [ ] Semantic view returns results
- [ ] Search service is active
- [ ] ML model is registered (if applicable)
- [ ] Agent is created
- [ ] Test client authenticates successfully
- [ ] Each tool responds correctly
- [ ] Combined questions work
- [ ] README documentation is accurate
