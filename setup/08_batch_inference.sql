-- ============================================================
-- 08_batch_inference.sql
-- Runs batch inference on TRANSACTIONS table using the ML model
-- Creates PREDICTION_LOG for monitoring and PREDICTION_BASELINE for drift detection
--
-- Prerequisites:
-- - FRAUD_DETECTION_MODEL must exist in WORKSHOP_DB.DEMO
-- - TRANSACTIONS table must be populated
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Step 1: Create Prediction Log Table with Change Tracking
-- ============================================================
-- IMPORTANT: Change tracking must be enabled BEFORE inserting data
-- for the Model Monitor to work properly

DROP TABLE IF EXISTS PREDICTION_LOG;

CREATE TABLE PREDICTION_LOG (
    TRANSACTION_ID VARCHAR,
    AMOUNT NUMBER(38,2),
    TRANSACTION_TYPE VARCHAR,
    CHANNEL VARCHAR,
    LOCATION VARCHAR,
    MERCHANT VARCHAR,
    ACTUAL_FRAUD INT,
    PREDICTION_TIMESTAMP TIMESTAMP_NTZ,
    PREDICTED_FRAUD INT
) CHANGE_TRACKING = TRUE;

-- ============================================================
-- Step 2: Run Batch Inference with Historical Timestamps
-- ============================================================
-- Spreads timestamps across last 30 days for meaningful time-series monitoring
-- In production, this would be run periodically (e.g., daily) with actual timestamps

INSERT INTO PREDICTION_LOG
SELECT 
    t.TRANSACTION_ID,
    t.AMOUNT,
    t.TRANSACTION_TYPE,
    t.CHANNEL,
    t.LOCATION,
    t.MERCHANT,
    t.IS_FRAUD::INT AS ACTUAL_FRAUD,
    -- Spread timestamps over last 30 days based on hash of transaction ID
    -- This simulates historical predictions for demo purposes
    DATEADD('minute', 
        -1 * MOD(ABS(HASH(t.TRANSACTION_ID)), 43200),  -- 43200 minutes = 30 days
        CURRENT_TIMESTAMP()
    )::TIMESTAMP_NTZ AS PREDICTION_TIMESTAMP,
    FRAUD_DETECTION_MODEL!PREDICT(
        t.AMOUNT, t.TRANSACTION_TYPE, t.CHANNEL, t.LOCATION, t.MERCHANT
    ):IS_FRAUD::INT AS PREDICTED_FRAUD
FROM TRANSACTIONS t;

-- Verify prediction log
SELECT 
    COUNT(*) as total_predictions,
    SUM(PREDICTED_FRAUD) as predicted_fraud_count,
    SUM(ACTUAL_FRAUD) as actual_fraud_count,
    ROUND(AVG(PREDICTED_FRAUD) * 100, 2) as predicted_fraud_rate_pct,
    ROUND(AVG(ACTUAL_FRAUD) * 100, 2) as actual_fraud_rate_pct,
    MIN(PREDICTION_TIMESTAMP) as earliest_prediction,
    MAX(PREDICTION_TIMESTAMP) as latest_prediction,
    COUNT(DISTINCT DATE(PREDICTION_TIMESTAMP)) as unique_days
FROM PREDICTION_LOG;

-- ============================================================
-- Step 3: Create Baseline Table for Drift Detection
-- ============================================================
-- Uses first week of predictions as baseline
-- Monitor will compare recent predictions against this baseline

DROP TABLE IF EXISTS PREDICTION_BASELINE;

CREATE TABLE PREDICTION_BASELINE CHANGE_TRACKING = TRUE AS
SELECT * FROM PREDICTION_LOG
WHERE PREDICTION_TIMESTAMP < DATEADD('day', -23, CURRENT_TIMESTAMP());

-- Verify baseline
SELECT 
    'BASELINE' as table_name,
    COUNT(*) as row_count,
    MIN(PREDICTION_TIMESTAMP) as earliest,
    MAX(PREDICTION_TIMESTAMP) as latest
FROM PREDICTION_BASELINE
UNION ALL
SELECT 
    'PREDICTION_LOG' as table_name,
    COUNT(*) as row_count,
    MIN(PREDICTION_TIMESTAMP) as earliest,
    MAX(PREDICTION_TIMESTAMP) as latest
FROM PREDICTION_LOG;

-- ============================================================
-- Production Usage Notes
-- ============================================================
-- In production, you would:
-- 1. Run batch inference on a schedule (e.g., daily via Task)
-- 2. Append new predictions to PREDICTION_LOG (not replace)
-- 3. Use actual timestamps from when predictions were made
--
-- Example Task for daily batch inference:
-- CREATE OR REPLACE TASK DAILY_FRAUD_SCORING
--     WAREHOUSE = WORKSHOP_WH
--     SCHEDULE = 'USING CRON 0 6 * * * America/Los_Angeles'
-- AS
-- INSERT INTO PREDICTION_LOG
-- SELECT 
--     t.TRANSACTION_ID,
--     t.AMOUNT,
--     t.TRANSACTION_TYPE,
--     t.CHANNEL,
--     t.LOCATION,
--     t.MERCHANT,
--     t.IS_FRAUD::INT AS ACTUAL_FRAUD,
--     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS PREDICTION_TIMESTAMP,
--     FRAUD_DETECTION_MODEL!PREDICT(...):IS_FRAUD::INT AS PREDICTED_FRAUD
-- FROM TRANSACTIONS t
-- WHERE t.TRANSACTION_DATE = CURRENT_DATE() - 1;  -- Yesterday's transactions
