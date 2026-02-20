-- ============================================================
-- 08_create_ml_forecast_model.sql
-- Creates Snowflake ML FORECAST model for cost prediction
-- 
-- Prerequisites: Run 01_billing_data.sql first (needs BILLING_DATA table)
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create training view for the ML model
CREATE OR REPLACE VIEW BILLING_FORECAST_INPUT AS
SELECT 
    BILLING_DATE AS DS,
    SERVICE,
    SUM(COST) AS Y
FROM BILLING_DATA
GROUP BY BILLING_DATE, SERVICE
ORDER BY BILLING_DATE, SERVICE;

-- Verify training data
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT SERVICE) AS services,
    MIN(DS) AS start_date,
    MAX(DS) AS end_date
FROM BILLING_FORECAST_INPUT;

-- Create Snowflake ML FORECAST model
-- This trains a time series model for each service
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST COST_FORECAST_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'WORKSHOP_DB.DEMO.BILLING_FORECAST_INPUT'),
    TIMESTAMP_COLNAME => 'DS',
    TARGET_COLNAME => 'Y',
    SERIES_COLNAME => 'SERVICE'
);

-- Test the model with a 7-day forecast
SELECT 
    SERIES AS SERVICE,
    TS::DATE AS FORECAST_DATE,
    ROUND(FORECAST, 2) AS PREDICTED_COST,
    ROUND(LOWER_BOUND, 2) AS LOW_ESTIMATE,
    ROUND(UPPER_BOUND, 2) AS HIGH_ESTIMATE
FROM TABLE(COST_FORECAST_MODEL!FORECAST(FORECASTING_PERIODS => 7))
WHERE SERIES = 'EC2'
ORDER BY TS;

-- Show model info
SHOW SNOWFLAKE.ML.FORECAST LIKE 'COST_FORECAST_MODEL' IN SCHEMA WORKSHOP_DB.DEMO;
