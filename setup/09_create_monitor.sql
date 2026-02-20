-- ============================================================
-- 09_create_monitor.sql
-- Creates a Model Monitor to track cost forecasting performance
-- Monitors for drift, accuracy degradation, and data quality issues
--
-- Prerequisites:
-- - COST_FORECASTING_MODEL registered in WORKSHOP_DB.DEMO
-- - FORECAST_LOG and FORECAST_BASELINE tables exist with change tracking
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Step 1: Verify Prerequisites
-- ============================================================
-- Check model exists
SHOW MODELS IN SCHEMA DEMO;

-- Check tables have change tracking
SELECT 
    TABLE_NAME,
    CHANGE_TRACKING
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'DEMO' 
  AND TABLE_NAME IN ('FORECAST_LOG', 'FORECAST_BASELINE');

-- ============================================================
-- Step 2: Create Model Monitor
-- ============================================================
-- Note: You may need to get the exact version name from SHOW MODELS
-- Replace 'V1' with the actual version name

CREATE OR REPLACE MODEL MONITOR COST_MODEL_MONITOR WITH
    MODEL = COST_FORECASTING_MODEL
    VERSION = 'V1'  -- Update this to match your model version
    FUNCTION = 'PREDICT'
    SOURCE = FORECAST_LOG
    WAREHOUSE = WORKSHOP_WH
    REFRESH_INTERVAL = '1 hour'
    AGGREGATION_WINDOW = '1 day'
    TIMESTAMP_COLUMN = PREDICTION_TIMESTAMP
    PREDICTION_SCORE_COLUMNS = ('PREDICTED_COST')
    ACTUAL_SCORE_COLUMNS = ('ACTUAL_COST')
    BASELINE = FORECAST_BASELINE;

-- ============================================================
-- Step 3: Verify Monitor Created
-- ============================================================
SHOW MODEL MONITORS;
DESCRIBE MODEL MONITOR COST_MODEL_MONITOR;

-- ============================================================
-- Step 4: Query Monitor Metrics
-- ============================================================
-- Note: Metrics will populate after the first refresh (up to 1 hour)

-- MAE (Mean Absolute Error)
-- SELECT *
-- FROM TABLE(MODEL_MONITOR_PERFORMANCE_METRIC(
--     'COST_MODEL_MONITOR',
--     'MAE',
--     '1 DAY',
--     DATEADD('day', -30, CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
--     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
-- ));

-- RMSE (Root Mean Square Error)
-- SELECT *
-- FROM TABLE(MODEL_MONITOR_PERFORMANCE_METRIC(
--     'COST_MODEL_MONITOR',
--     'RMSE',
--     '1 DAY',
--     DATEADD('day', -30, CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
--     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
-- ));

-- MAPE (Mean Absolute Percentage Error)
-- SELECT *
-- FROM TABLE(MODEL_MONITOR_PERFORMANCE_METRIC(
--     'COST_MODEL_MONITOR',
--     'MAPE',
--     '1 DAY',
--     DATEADD('day', -30, CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
--     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
-- ));

-- Drift on predicted costs
-- SELECT *
-- FROM TABLE(MODEL_MONITOR_DRIFT_METRIC(
--     'COST_MODEL_MONITOR',
--     'WASSERSTEIN',
--     'PREDICTED_COST',
--     '1 DAY',
--     DATEADD('day', -30, CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
--     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
-- ));

-- ============================================================
-- Useful Commands
-- ============================================================
-- Suspend monitoring:
-- ALTER MODEL MONITOR COST_MODEL_MONITOR SUSPEND;

-- Resume monitoring:
-- ALTER MODEL MONITOR COST_MODEL_MONITOR RESUME;

-- Update baseline after retraining:
-- ALTER MODEL MONITOR COST_MODEL_MONITOR SET BASELINE = FORECAST_BASELINE;

-- View in Snowsight: AI & ML → Models → COST_FORECASTING_MODEL → Monitors
