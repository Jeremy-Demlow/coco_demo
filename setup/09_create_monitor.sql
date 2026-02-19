-- ============================================================
-- 09_create_monitor.sql
-- Creates Model Monitor for ML Observability
-- Tracks drift, accuracy, and statistics over time
--
-- Prerequisites:
-- - FRAUD_DETECTION_MODEL must exist in Model Registry
-- - PREDICTION_LOG table must exist (run 08_batch_inference.sql first)
-- - PREDICTION_BASELINE table must exist
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Step 1: Create Model Monitor
-- ============================================================
-- Monitor watches PREDICTION_LOG table and compares against PREDICTION_BASELINE

CREATE OR REPLACE MODEL MONITOR FRAUD_MODEL_MONITOR WITH
    MODEL = FRAUD_DETECTION_MODEL
    VERSION = 'WITTY_CHICKEN_3'           -- Update if model version changes
    FUNCTION = 'PREDICT'
    SOURCE = PREDICTION_LOG
    WAREHOUSE = WORKSHOP_WH
    REFRESH_INTERVAL = '1 hour'           -- How often to refresh metrics
    AGGREGATION_WINDOW = '1 day'          -- Aggregate metrics by day
    TIMESTAMP_COLUMN = PREDICTION_TIMESTAMP
    PREDICTION_CLASS_COLUMNS = ('PREDICTED_FRAUD')
    ACTUAL_CLASS_COLUMNS = ('ACTUAL_FRAUD')
    BASELINE = PREDICTION_BASELINE;

-- ============================================================
-- Step 2: Verify Monitor Status
-- ============================================================

-- Check monitor is active
DESC MODEL MONITOR FRAUD_MODEL_MONITOR;

-- List all monitors in schema
SHOW MODEL MONITORS IN SCHEMA WORKSHOP_DB.DEMO;

-- ============================================================
-- Step 3: Query Metrics (after first refresh)
-- ============================================================
-- Note: Metrics will be empty until the first refresh runs

-- Performance metrics (accuracy, precision, recall, F1)
-- SELECT * FROM TABLE(FRAUD_MODEL_MONITOR!MODEL_MONITOR_PERFORMANCE_METRIC(
--     'ACCURACY',
--     'DAY',
--     DATEADD('day', -30, CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
--     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
-- ));

-- Drift metrics (PSI - Population Stability Index)
-- SELECT * FROM TABLE(FRAUD_MODEL_MONITOR!MODEL_MONITOR_DRIFT_METRIC(
--     'PSI',
--     'AMOUNT',
--     'DAY',
--     DATEADD('day', -30, CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
--     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
-- ));

-- ============================================================
-- Monitor Management Commands
-- ============================================================

-- Suspend monitoring
-- ALTER MODEL MONITOR FRAUD_MODEL_MONITOR SUSPEND;

-- Resume monitoring  
-- ALTER MODEL MONITOR FRAUD_MODEL_MONITOR RESUME;

-- Change refresh interval
-- ALTER MODEL MONITOR FRAUD_MODEL_MONITOR SET REFRESH_INTERVAL = '6 hours';

-- Update baseline
-- ALTER MODEL MONITOR FRAUD_MODEL_MONITOR SET BASELINE = NEW_BASELINE_TABLE;

-- Drop monitor (careful - loses all history)
-- DROP MODEL MONITOR FRAUD_MODEL_MONITOR;

-- ============================================================
-- Viewing in Snowsight
-- ============================================================
-- Navigate to: AI & ML -> Models -> FRAUD_DETECTION_MODEL -> Monitors
-- You'll see:
--   - Drift charts (PSI over time for each feature)
--   - Performance charts (accuracy, precision, recall over time)
--   - Distribution comparisons (baseline vs current)
