-- ============================================================
-- 03b_create_semantic_view.sql
-- Creates DEMO_SEMANTIC_VIEW for transaction fraud analysis
-- 
-- Best Practices Applied:
-- - Clear descriptions for all columns with business context
-- - Synonyms for common alternative terms  
-- - Comprehensive fraud detection metrics including precision/recall
-- - Named filters for common analysis patterns
-- - AI_SQL_GENERATION instructions for proper metric usage
--
-- NOTE: For sample_values and unique flags on dimensions, use YAML syntax
-- via SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML. SQL syntax supports these
-- only at table level (UNIQUE clause).
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

CREATE OR REPLACE SEMANTIC VIEW DEMO_SEMANTIC_VIEW

    TABLES (
        transactions AS WORKSHOP_DB.DEMO.TRANSACTIONS
            PRIMARY KEY (TRANSACTION_ID)
            UNIQUE (CUSTOMER_ID)
            COMMENT = 'Financial transactions with fraud detection flags and customer service notes. Each row represents a single transaction with IS_FLAGGED (system prediction) and IS_FRAUD (confirmed ground truth).'
    )

    DIMENSIONS (
        -- Time dimensions
        transactions.transaction_date AS TRANSACTION_DATE
            COMMENT = 'Date of the transaction. Use for time-series analysis and trend detection.',
        transactions.transaction_year AS YEAR(TRANSACTION_DATE)
            WITH SYNONYMS = ('year')
            COMMENT = 'Year extracted from transaction date. Use for annual comparisons.',
        transactions.transaction_month AS MONTH(TRANSACTION_DATE)
            WITH SYNONYMS = ('month')
            COMMENT = 'Month number (1-12) extracted from transaction date. Use for monthly trends.',
        
        -- Transaction attributes
        transactions.transaction_id AS TRANSACTION_ID
            COMMENT = 'Unique transaction identifier (e.g., TXN_0000001). Primary key for the transactions table.',
        transactions.channel AS CHANNEL
            WITH SYNONYMS = ('payment channel', 'transaction channel', 'payment method')
            COMMENT = 'Channel used for the transaction. Valid values: Online, In-Store, Mobile App, Phone, ATM. Online and Mobile App channels typically have higher fraud rates.',
        transactions.location AS LOCATION
            WITH SYNONYMS = ('city', 'transaction location', 'place')
            COMMENT = 'Geographic city where the transaction occurred (e.g., New York, Los Angeles, Chicago). Use for regional fraud pattern analysis.',
        transactions.transaction_type AS TRANSACTION_TYPE
            WITH SYNONYMS = ('type', 'txn type', 'transaction category')
            COMMENT = 'Type of transaction. Valid values: Purchase, Refund, Transfer, Withdrawal, Deposit. Refunds and Transfers may have different fraud patterns.',
        transactions.merchant AS MERCHANT
            WITH SYNONYMS = ('vendor', 'store', 'merchant name', 'retailer')
            COMMENT = 'Merchant name where the transaction occurred (e.g., Amazon, Walmart, Target). Some merchants may have higher fraud exposure.',
        transactions.amount AS AMOUNT
            WITH SYNONYMS = ('value', 'transaction amount', 'dollar amount', 'dollars', 'price')
            COMMENT = 'Transaction amount in USD. Fraud transactions often have unusual amounts (very high or specific round values like $500, $1000).',
        
        -- Fraud indicators (CRITICAL: understand the difference)
        transactions.is_flagged AS IS_FLAGGED
            WITH SYNONYMS = ('flagged', 'suspicious', 'predicted fraud', 'system flag')
            COMMENT = 'System prediction flag (boolean TRUE/FALSE): TRUE means the system flagged this as potentially fraudulent. This is the PREDICTION from the fraud detection model, NOT ground truth. Use with IS_FRAUD to calculate precision/recall.',
        transactions.is_fraud AS IS_FRAUD
            WITH SYNONYMS = ('fraud', 'confirmed fraud', 'fraudulent', 'actual fraud', 'ground truth')
            COMMENT = 'Confirmed fraud indicator (boolean TRUE/FALSE): TRUE means this transaction was verified as fraudulent after investigation. This is the GROUND TRUTH label. Compare with IS_FLAGGED to measure detection accuracy.',
        
        -- Customer info
        transactions.customer_name AS CUSTOMER_NAME
            WITH SYNONYMS = ('name', 'client name', 'customer')
            COMMENT = 'Full name of the customer. Use for customer-level fraud analysis.',
        transactions.customer_id AS CUSTOMER_ID
            WITH SYNONYMS = ('cust id', 'client id')
            COMMENT = 'Unique customer identifier (e.g., CUST_00001). One customer may have multiple transactions.'
    )

    METRICS (
        -- Count metrics
        transactions.transaction_count AS COUNT(TRANSACTION_ID)
            WITH SYNONYMS = ('number of transactions', 'txn count', 'count', 'total transactions', 'volume')
            COMMENT = 'Total number of transactions',
        transactions.unique_customers AS COUNT(DISTINCT CUSTOMER_ID)
            WITH SYNONYMS = ('customer count', 'distinct customers', 'number of customers')
            COMMENT = 'Number of unique customers',
        
        -- Amount metrics
        transactions.total_amount AS SUM(AMOUNT)
            WITH SYNONYMS = ('total value', 'sum of amounts', 'total', 'total dollars', 'revenue')
            COMMENT = 'Total monetary value of all transactions in USD',
        transactions.avg_amount AS AVG(AMOUNT)
            WITH SYNONYMS = ('average value', 'mean amount', 'average', 'avg transaction')
            COMMENT = 'Average transaction amount in USD',
        transactions.max_amount AS MAX(AMOUNT)
            WITH SYNONYMS = ('highest amount', 'maximum', 'largest transaction')
            COMMENT = 'Highest single transaction amount',
        transactions.min_amount AS MIN(AMOUNT)
            WITH SYNONYMS = ('lowest amount', 'minimum', 'smallest transaction')
            COMMENT = 'Lowest single transaction amount',
        
        -- Flagged metrics (system predictions)
        transactions.flagged_count AS COUNT_IF(IS_FLAGGED = TRUE)
            WITH SYNONYMS = ('flagged transactions', 'suspicious count', 'predicted fraud count')
            COMMENT = 'Number of transactions flagged by the fraud detection system (predictions)',
        transactions.flagged_rate AS COUNT_IF(IS_FLAGGED = TRUE) / NULLIF(COUNT(TRANSACTION_ID), 0)
            WITH SYNONYMS = ('flag rate', 'suspicious rate', 'prediction rate')
            COMMENT = 'Percentage of transactions flagged by system (prediction rate)',
        
        -- Confirmed fraud metrics (ground truth)
        transactions.fraud_count AS COUNT_IF(IS_FRAUD = TRUE)
            WITH SYNONYMS = ('confirmed fraud count', 'actual fraud', 'true fraud count')
            COMMENT = 'Number of confirmed fraudulent transactions (ground truth)',
        transactions.fraud_rate AS COUNT_IF(IS_FRAUD = TRUE) / NULLIF(COUNT(TRANSACTION_ID), 0)
            WITH SYNONYMS = ('fraud rate', 'fraud percentage', 'confirmed fraud rate')
            COMMENT = 'Percentage of transactions that are confirmed fraud',
        
        -- Financial impact metrics
        transactions.fraud_amount AS SUM(CASE WHEN IS_FRAUD = TRUE THEN AMOUNT ELSE 0 END)
            WITH SYNONYMS = ('fraud dollars', 'fraud losses', 'money lost to fraud', 'fraud value')
            COMMENT = 'Total dollar amount lost to confirmed fraud',
        transactions.avg_fraud_amount AS AVG(CASE WHEN IS_FRAUD = TRUE THEN AMOUNT ELSE NULL END)
            WITH SYNONYMS = ('average fraud value', 'typical fraud amount')
            COMMENT = 'Average dollar amount of fraudulent transactions',
        
        -- Model performance metrics (precision/recall)
        transactions.true_positives AS COUNT_IF(IS_FLAGGED = TRUE AND IS_FRAUD = TRUE)
            WITH SYNONYMS = ('correct fraud predictions', 'caught fraud')
            COMMENT = 'Transactions correctly flagged as fraud (flagged=true AND fraud=true)',
        transactions.false_positives AS COUNT_IF(IS_FLAGGED = TRUE AND IS_FRAUD = FALSE)
            WITH SYNONYMS = ('false alarms', 'incorrect flags', 'wrongly flagged')
            COMMENT = 'Legitimate transactions incorrectly flagged as fraud (flagged=true AND fraud=false)',
        transactions.false_negatives AS COUNT_IF(IS_FLAGGED = FALSE AND IS_FRAUD = TRUE)
            WITH SYNONYMS = ('missed fraud', 'undetected fraud', 'fraud not caught')
            COMMENT = 'Fraudulent transactions that were not flagged (flagged=false AND fraud=true)',
        transactions.precision_rate AS COUNT_IF(IS_FLAGGED = TRUE AND IS_FRAUD = TRUE) / NULLIF(COUNT_IF(IS_FLAGGED = TRUE), 0)
            WITH SYNONYMS = ('precision', 'positive predictive value', 'ppv')
            COMMENT = 'Of all flagged transactions, what percentage were actually fraud? Higher is better.',
        transactions.recall_rate AS COUNT_IF(IS_FLAGGED = TRUE AND IS_FRAUD = TRUE) / NULLIF(COUNT_IF(IS_FRAUD = TRUE), 0)
            WITH SYNONYMS = ('recall', 'sensitivity', 'detection rate', 'catch rate')
            COMMENT = 'Of all actual fraud, what percentage was flagged? Higher means fewer missed fraud cases.'
    )

    COMMENT = 'Semantic view for analyzing financial transactions with fraud detection metrics. Includes both system predictions (IS_FLAGGED) and confirmed fraud labels (IS_FRAUD) for model performance analysis. Key metrics: fraud_rate (actual fraud %), precision_rate (accuracy of flags), recall_rate (fraud detection coverage).'
    
    AI_SQL_GENERATION 'When asked about fraud detection accuracy or model performance, use the precision_rate and recall_rate metrics. When asked about financial impact of fraud, use fraud_amount metric. IMPORTANT: IS_FLAGGED is the system PREDICTION (what the model thinks is fraud), IS_FRAUD is the confirmed GROUND TRUTH (actual verified fraud). Be explicit about which one is being analyzed. For channel analysis, valid values are: Online, In-Store, Mobile App, Phone, ATM. For transaction_type analysis, valid values are: Purchase, Refund, Transfer, Withdrawal, Deposit.';

-- Verify semantic view was created
DESCRIBE SEMANTIC VIEW WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW;
