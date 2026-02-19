-- ============================================================
-- 06_populate_fraud_labels.sql
-- Populates IS_FRAUD column based on business rules
-- Run AFTER loading data from CSV
-- 
-- IS_FRAUD Target Variable Rules:
-- 1. Transaction is flagged AND amount exceeds $1000
-- 2. NOTES_TEXT contains "unauthorized" or "account takeover" or "fraud signature"
-- 3. ATM withdrawals exceeding $2500
-- 4. Refunds exceeding $2000 from Online channel
-- 5. Transaction is flagged AND NOTES_TEXT mentions "suspicious IP"
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

UPDATE TRANSACTIONS
SET IS_FRAUD = CASE
    WHEN IS_FLAGGED = TRUE AND AMOUNT > 1000 THEN TRUE
    WHEN LOWER(NOTES_TEXT) LIKE '%unauthorized%' THEN TRUE
    WHEN LOWER(NOTES_TEXT) LIKE '%account takeover%' THEN TRUE
    WHEN LOWER(NOTES_TEXT) LIKE '%fraud signature%' THEN TRUE
    WHEN CHANNEL = 'ATM' AND TRANSACTION_TYPE = 'Withdrawal' AND AMOUNT > 2500 THEN TRUE
    WHEN CHANNEL = 'Online' AND TRANSACTION_TYPE = 'Refund' AND AMOUNT > 2000 THEN TRUE
    WHEN IS_FLAGGED = TRUE AND LOWER(NOTES_TEXT) LIKE '%suspicious ip%' THEN TRUE
    ELSE FALSE
END;

-- Verify fraud distribution
SELECT 
    COUNT(*) AS total_transactions,
    COUNT_IF(IS_FRAUD = TRUE) AS fraud_count,
    ROUND(COUNT_IF(IS_FRAUD = TRUE) * 100.0 / COUNT(*), 1) AS fraud_rate_pct
FROM TRANSACTIONS;
