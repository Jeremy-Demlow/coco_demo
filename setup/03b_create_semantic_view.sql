-- ============================================================
-- 03b_create_semantic_view.sql
-- Creates DEMO_SEMANTIC_VIEW for transaction fraud analysis
-- 
-- Best Practices Applied:
-- - Clear descriptions for all columns
-- - Synonyms for common alternative terms
-- - Metrics include fraud-specific calculations
-- - IS_FRAUD column included for confirmed fraud analysis
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

CREATE OR REPLACE SEMANTIC VIEW DEMO_SEMANTIC_VIEW

    TABLES (
        transactions AS WORKSHOP_DB.DEMO.TRANSACTIONS
            PRIMARY KEY (TRANSACTION_ID)
            COMMENT = 'Financial transactions with fraud detection and customer service notes'
    )

    DIMENSIONS (
        -- Time dimensions
        transactions.transaction_date AS TRANSACTION_DATE
            COMMENT = 'Date of the transaction',
        transactions.transaction_year AS YEAR(TRANSACTION_DATE)
            COMMENT = 'Year of the transaction',
        transactions.transaction_month AS MONTH(TRANSACTION_DATE)
            COMMENT = 'Month of the transaction',
        
        -- Transaction attributes
        transactions.transaction_id AS TRANSACTION_ID
            COMMENT = 'Unique transaction identifier',
        transactions.channel AS CHANNEL
            WITH SYNONYMS = ('payment channel', 'transaction channel')
            COMMENT = 'Channel used for the transaction (Online, In-Store, Mobile App, Phone, ATM)',
        transactions.location AS LOCATION
            WITH SYNONYMS = ('city', 'transaction location')
            COMMENT = 'Geographic location of the transaction',
        transactions.transaction_type AS TRANSACTION_TYPE
            WITH SYNONYMS = ('type', 'txn type')
            COMMENT = 'Type of transaction (Purchase, Refund, Transfer, Withdrawal, Deposit)',
        transactions.merchant AS MERCHANT
            WITH SYNONYMS = ('vendor', 'store', 'merchant name')
            COMMENT = 'Merchant name where the transaction occurred',
        transactions.amount AS AMOUNT
            WITH SYNONYMS = ('value', 'transaction amount', 'dollar amount')
            COMMENT = 'Transaction amount in dollars',
        
        -- Fraud indicators
        transactions.is_flagged AS IS_FLAGGED
            WITH SYNONYMS = ('flagged', 'suspicious', 'fraud flag')
            COMMENT = 'Whether the transaction is flagged for potential fraud (system flag)',
        transactions.is_fraud AS IS_FRAUD
            WITH SYNONYMS = ('fraud', 'confirmed fraud', 'fraudulent')
            COMMENT = 'Whether the transaction is confirmed fraud (TRUE = confirmed fraud)',
        
        -- Customer info
        transactions.customer_name AS CUSTOMER_NAME
            WITH SYNONYMS = ('name', 'client name')
            COMMENT = 'Name of the customer',
        transactions.customer_id AS CUSTOMER_ID
            COMMENT = 'Unique identifier for the customer'
    )

    METRICS (
        -- Count metrics
        transactions.transaction_count AS COUNT(TRANSACTION_ID)
            WITH SYNONYMS = ('number of transactions', 'txn count', 'count', 'total transactions')
            COMMENT = 'Total number of transactions',
        transactions.unique_customers AS COUNT(DISTINCT CUSTOMER_ID)
            WITH SYNONYMS = ('customer count', 'distinct customers', 'number of customers')
            COMMENT = 'Number of unique customers',
        
        -- Amount metrics
        transactions.total_amount AS SUM(AMOUNT)
            WITH SYNONYMS = ('total value', 'sum of amounts', 'total', 'total dollars')
            COMMENT = 'Total monetary value of transactions',
        transactions.avg_amount AS AVG(AMOUNT)
            WITH SYNONYMS = ('average value', 'mean amount', 'average', 'avg transaction')
            COMMENT = 'Average transaction amount',
        transactions.max_amount AS MAX(AMOUNT)
            WITH SYNONYMS = ('highest amount', 'maximum', 'largest transaction')
            COMMENT = 'Highest transaction amount',
        transactions.min_amount AS MIN(AMOUNT)
            WITH SYNONYMS = ('lowest amount', 'minimum', 'smallest transaction')
            COMMENT = 'Lowest transaction amount',
        
        -- Fraud metrics (using IS_FLAGGED - system flag)
        transactions.flagged_count AS COUNT_IF(IS_FLAGGED = TRUE)
            WITH SYNONYMS = ('flagged transactions', 'suspicious count')
            COMMENT = 'Number of transactions flagged by system',
        transactions.flagged_rate AS COUNT_IF(IS_FLAGGED = TRUE) / NULLIF(COUNT(TRANSACTION_ID), 0)
            WITH SYNONYMS = ('flag rate', 'suspicious rate')
            COMMENT = 'Percentage of transactions flagged by system',
        
        -- Fraud metrics (using IS_FRAUD - confirmed fraud)
        transactions.fraud_count AS COUNT_IF(IS_FRAUD = TRUE)
            WITH SYNONYMS = ('confirmed fraud count', 'actual fraud')
            COMMENT = 'Number of confirmed fraudulent transactions',
        transactions.fraud_rate AS COUNT_IF(IS_FRAUD = TRUE) / NULLIF(COUNT(TRANSACTION_ID), 0)
            WITH SYNONYMS = ('fraud rate', 'fraud percentage', 'confirmed fraud rate')
            COMMENT = 'Percentage of transactions that are confirmed fraud'
    )

    COMMENT = 'Semantic view for analyzing financial transactions with fraud detection and customer experience metrics';

-- Verify semantic view was created
DESCRIBE SEMANTIC VIEW WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW;
