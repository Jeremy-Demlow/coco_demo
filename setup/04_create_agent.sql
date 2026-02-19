-- ============================================================
-- 04_create_agent.sql
-- Creates DEMO_AGENT with Cortex Analyst, Cortex Search, and ML prediction tools
-- 
-- IMPORTANT: execution_environment is REQUIRED for warehouse access
-- Prerequisites: Run 07_create_prediction_procedure.sql first for ML predictions
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

CREATE OR REPLACE AGENT DEMO_AGENT
    COMMENT = 'Transaction fraud analysis agent - combines structured analytics, unstructured search, and ML predictions'
    FROM SPECIFICATION
    $$
    models:
      orchestration: auto

    orchestration:
      budget:
        seconds: 900
        tokens: 400000

    instructions:
      orchestration: |
        You are a Transaction Fraud Analyst assistant. Your audience is busy executives and compliance officers who need quick, actionable insights.

        RESPONSE STYLE:
        - Lead with the answer, not the methodology
        - Be concise: 2-3 sentences max for simple questions
        - Use bullet points for lists (max 5 items)
        - Include specific numbers and percentages
        - End with 1-2 recommended actions when relevant

        TOOL SELECTION:
        - Use Analyst1 for: counts, totals, rates, trends, comparisons, rankings, any numerical analysis
        - Use Search1 for: investigating specific transactions, finding notes mentioning keywords, understanding why something was flagged
        - Use FraudPredictor for: predicting fraud risk on a specific transaction by ID, getting ML model assessment

        IMPORTANT RULES:
        - Always include dollar amounts when discussing transactions
        - Express rates as percentages (e.g., "30%" not "0.30")
        - Round to 2 decimal places for money, 1 decimal for percentages
        - If asked about fraud, check the IS_FRAUD column (TRUE = confirmed fraud)
        - For fraud PREDICTIONS, use the FraudPredictor tool

      response: |
        Format all responses for executive consumption:
        - No technical jargon or SQL references
        - Bold key numbers and findings
        - Use tables only for 3+ comparable items
        - Maximum 150 words unless user asks for detail
        - Always end investigation questions with "Next steps:" recommendation

    tools:
      - tool_spec:
          type: cortex_analyst_text_to_sql
          name: Analyst1
          description: |
            Analyzes transaction data for metrics, trends, and patterns.

            DATA COVERAGE:
            - 100,000 transaction records with fraud indicators
            - Fields: TRANSACTION_ID, TRANSACTION_DATE, TRANSACTION_TYPE, AMOUNT, CHANNEL, 
              LOCATION, MERCHANT, CUSTOMER_ID, CUSTOMER_NAME, IS_FLAGGED, IS_FRAUD, NOTES_TEXT

            WHEN TO USE:
            - Transaction counts, totals, averages by any dimension
            - Fraud rates and flagged transaction analysis (use IS_FRAUD=TRUE for confirmed fraud)
            - Comparisons by channel, location, merchant, customer
            - Top N rankings (highest amounts, most flagged, etc.)
            - Aggregate statistics and trends

            WHEN NOT TO USE:
            - Do NOT use for searching text in notes (use Search1 instead)
            - Do NOT use for finding specific keywords in investigation details
            - Do NOT use for predicting fraud risk (use FraudPredictor instead)

      - tool_spec:
          type: cortex_search
          name: Search1
          description: |
            Searches transaction NOTES_TEXT for investigation details and keywords.

            DATA COVERAGE:
            - Unstructured text notes from transaction investigations
            - Contains fraud indicators, suspicious patterns, customer complaints

            WHEN TO USE:
            - Finding transactions mentioning specific terms (e.g., "unauthorized", "suspicious IP", "velocity")
            - Investigating why a transaction was flagged
            - Searching for patterns in customer service notes
            - Looking up details about specific transaction IDs

            WHEN NOT TO USE:
            - Do NOT use for counting or aggregating transactions (use Analyst1)
            - Do NOT use for calculating totals, rates, or rankings (use Analyst1)
            - Do NOT use for predicting fraud risk (use FraudPredictor instead)

      - tool_spec:
          type: generic
          name: FraudPredictor
          description: |
            Predicts fraud risk for a specific transaction using a trained ML model.

            RETURNS:
            - transaction details (amount, type, channel, merchant, location)
            - predicted_fraud: TRUE/FALSE from ML model
            - actual_fraud: TRUE/FALSE ground truth (if available)
            - risk_assessment: HIGH RISK, ELEVATED, or NORMAL with explanation

            WHEN TO USE:
            - "What's the fraud risk for transaction X?"
            - "Is transaction TXN_0001234 likely to be fraud?"
            - "Predict fraud for this transaction"
            - "Score this transaction"
            - Any question about predicting or assessing fraud risk for a specific transaction

            WHEN NOT TO USE:
            - Do NOT use for aggregate analysis (use Analyst1)
            - Do NOT use for searching notes (use Search1)
          input_schema:
            type: object
            properties:
              TRANSACTION_ID:
                type: string
                description: "The transaction ID to predict fraud for, e.g. TXN_0000123"
            required:
              - TRANSACTION_ID

    tool_resources:
      Analyst1:
        semantic_view: "WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW"
        execution_environment:
          type: warehouse
          warehouse: "WORKSHOP_WH"
          query_timeout: 299
      Search1:
        search_service: "WORKSHOP_DB.DEMO.TEXT_SEARCH"
        execution_environment:
          type: warehouse
          warehouse: "WORKSHOP_WH"
          query_timeout: 299
      FraudPredictor:
        type: procedure
        identifier: "WORKSHOP_DB.DEMO.PREDICT_FRAUD"
        execution_environment:
          type: warehouse
          warehouse: "WORKSHOP_WH"
    $$;

-- Verify agent was created
SHOW AGENTS LIKE 'DEMO_AGENT' IN SCHEMA WORKSHOP_DB.DEMO;
