-- ============================================================
-- 08_batch_inference.sql
-- Runs batch cost forecasting and creates monitoring tables
-- Creates FORECAST_LOG for monitoring and FORECAST_BASELINE for drift detection
--
-- Prerequisites:
-- - COST_FORECASTING_MODEL must exist in WORKSHOP_DB.DEMO
-- - BILLING_DATA table must be populated
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Step 1: Create Forecast Log Table with Change Tracking
-- ============================================================
-- IMPORTANT: Change tracking must be enabled BEFORE inserting data
-- for the Model Monitor to work properly

DROP TABLE IF EXISTS FORECAST_LOG;

CREATE TABLE FORECAST_LOG (
    FORECAST_DATE DATE,
    TARGET_DATE DATE,
    CLOUD_PROVIDER VARCHAR(10),
    SERVICE VARCHAR(50),
    DEPARTMENT VARCHAR(50),
    PREDICTED_COST NUMBER(18,2),
    ACTUAL_COST NUMBER(18,2),
    PREDICTION_TIMESTAMP TIMESTAMP_NTZ
) CHANGE_TRACKING = TRUE;

-- ============================================================
-- Step 2: Generate Forecast Data
-- ============================================================
-- For demo purposes, we'll create "forecasts" that were made in the past
-- comparing to actual costs

INSERT INTO FORECAST_LOG
WITH daily_actuals AS (
    SELECT 
        BILLING_DATE,
        CLOUD_PROVIDER,
        SERVICE,
        DEPARTMENT,
        SUM(COST) AS ACTUAL_COST
    FROM BILLING_DATA
    WHERE BILLING_DATE >= DATEADD('day', -60, CURRENT_DATE())
    GROUP BY 1, 2, 3, 4
),
-- Simulate forecasts made 7 days before each actual date
forecasts AS (
    SELECT 
        DATEADD('day', -7, BILLING_DATE) AS FORECAST_DATE,
        BILLING_DATE AS TARGET_DATE,
        CLOUD_PROVIDER,
        SERVICE,
        DEPARTMENT,
        -- Add some noise to simulate forecast error
        ACTUAL_COST * (1 + (RANDOM() % 20 - 10) / 100.0) AS PREDICTED_COST,
        ACTUAL_COST
    FROM daily_actuals
)
SELECT 
    FORECAST_DATE,
    TARGET_DATE,
    CLOUD_PROVIDER,
    SERVICE,
    DEPARTMENT,
    ROUND(PREDICTED_COST, 2) AS PREDICTED_COST,
    ROUND(ACTUAL_COST, 2) AS ACTUAL_COST,
    DATEADD('minute', 
        -1 * MOD(ABS(HASH(CONCAT(FORECAST_DATE, SERVICE, DEPARTMENT))), 43200),
        CURRENT_TIMESTAMP()
    )::TIMESTAMP_NTZ AS PREDICTION_TIMESTAMP
FROM forecasts;

-- Verify forecast log
SELECT 
    COUNT(*) as total_forecasts,
    COUNT(DISTINCT TARGET_DATE) as unique_target_dates,
    ROUND(AVG(ABS(PREDICTED_COST - ACTUAL_COST)), 2) as avg_absolute_error,
    ROUND(AVG(ABS(PREDICTED_COST - ACTUAL_COST) / NULLIF(ACTUAL_COST, 0)) * 100, 2) as avg_pct_error,
    MIN(PREDICTION_TIMESTAMP) as earliest_forecast,
    MAX(PREDICTION_TIMESTAMP) as latest_forecast
FROM FORECAST_LOG;

-- ============================================================
-- Step 3: Create Baseline Table for Drift Detection
-- ============================================================
-- Uses first 3 weeks of forecasts as baseline

DROP TABLE IF EXISTS FORECAST_BASELINE;

CREATE TABLE FORECAST_BASELINE CHANGE_TRACKING = TRUE AS
SELECT * FROM FORECAST_LOG
WHERE PREDICTION_TIMESTAMP < DATEADD('day', -21, CURRENT_TIMESTAMP());

-- Verify baseline
SELECT 
    'BASELINE' as table_name,
    COUNT(*) as row_count,
    MIN(PREDICTION_TIMESTAMP) as earliest,
    MAX(PREDICTION_TIMESTAMP) as latest
FROM FORECAST_BASELINE
UNION ALL
SELECT 
    'FORECAST_LOG' as table_name,
    COUNT(*) as row_count,
    MIN(PREDICTION_TIMESTAMP) as earliest,
    MAX(PREDICTION_TIMESTAMP) as latest
FROM FORECAST_LOG;

-- ============================================================
-- Production Usage Notes
-- ============================================================
-- In production, you would:
-- 1. Run batch forecasting daily for the next 30 days
-- 2. Append new forecasts to FORECAST_LOG (not replace)
-- 3. Update ACTUAL_COST once the target date has passed
-- 4. Use the ML model for predictions instead of simple multipliers
--
-- Example Task for daily batch forecasting:
-- CREATE OR REPLACE TASK DAILY_COST_FORECAST
--     WAREHOUSE = WORKSHOP_WH
--     SCHEDULE = 'USING CRON 0 6 * * * America/Los_Angeles'
-- AS
-- INSERT INTO FORECAST_LOG
-- SELECT 
--     CURRENT_DATE() AS FORECAST_DATE,
--     DATEADD('day', seq4.seq, CURRENT_DATE()) AS TARGET_DATE,
--     CLOUD_PROVIDER,
--     SERVICE,
--     DEPARTMENT,
--     COST_FORECASTING_MODEL!PREDICT(...):PREDICTED_COST AS PREDICTED_COST,
--     NULL AS ACTUAL_COST,  -- Will be filled in later
--     CURRENT_TIMESTAMP() AS PREDICTION_TIMESTAMP
-- FROM (SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 30))) seq4
-- CROSS JOIN (SELECT DISTINCT CLOUD_PROVIDER, SERVICE, DEPARTMENT FROM BILLING_DATA);
