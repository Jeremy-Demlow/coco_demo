-- ============================================================
-- 99_teardown.sql
-- Cleanly removes all demo objects for fresh rebuild
-- 
-- Run this to reset the demo environment before rebuilding
-- Objects are dropped in reverse dependency order
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- DROP AGENT (depends on everything)
-- ============================================================
DROP AGENT IF EXISTS DEMO_AGENT;
SELECT 'Dropped: DEMO_AGENT' AS STATUS;

-- ============================================================
-- DROP ML OBJECTS
-- ============================================================
-- Drop monitor first (depends on model)
DROP MODEL MONITOR IF EXISTS FRAUD_MODEL_MONITOR;
SELECT 'Dropped: FRAUD_MODEL_MONITOR' AS STATUS;

-- Drop model (may have multiple versions)
DROP MODEL IF EXISTS FRAUD_DETECTION_MODEL;
SELECT 'Dropped: FRAUD_DETECTION_MODEL' AS STATUS;

-- Drop prediction procedure and UDF
DROP PROCEDURE IF EXISTS PREDICT_FRAUD(VARCHAR);
SELECT 'Dropped: PREDICT_FRAUD procedure' AS STATUS;

DROP FUNCTION IF EXISTS PREDICT_FRAUD_UDF(FLOAT, VARCHAR, VARCHAR, VARCHAR, VARCHAR);
SELECT 'Dropped: PREDICT_FRAUD_UDF function' AS STATUS;

-- Drop prediction log table
DROP TABLE IF EXISTS PREDICTION_LOG;
SELECT 'Dropped: PREDICTION_LOG table' AS STATUS;

-- ============================================================
-- DROP AI SERVICES
-- ============================================================
DROP SEMANTIC VIEW IF EXISTS DEMO_SEMANTIC_VIEW;
SELECT 'Dropped: DEMO_SEMANTIC_VIEW' AS STATUS;

DROP CORTEX SEARCH SERVICE IF EXISTS TEXT_SEARCH;
SELECT 'Dropped: TEXT_SEARCH service' AS STATUS;

-- ============================================================
-- DROP DATA OBJECTS
-- ============================================================
DROP TABLE IF EXISTS TRANSACTIONS;
SELECT 'Dropped: TRANSACTIONS table' AS STATUS;

-- Remove files from stage but keep stage
REMOVE @DATA_STAGE PATTERN='.*';
SELECT 'Cleared: DATA_STAGE files' AS STATUS;

-- ============================================================
-- OPTIONAL: Full reset (uncomment if needed)
-- ============================================================
-- DROP STAGE IF EXISTS DATA_STAGE;
-- DROP SCHEMA IF EXISTS DEMO;
-- DROP DATABASE IF EXISTS WORKSHOP_DB;
-- DROP WAREHOUSE IF EXISTS WORKSHOP_WH;

-- ============================================================
-- VERIFICATION
-- ============================================================
SHOW AGENTS LIKE 'DEMO%' IN SCHEMA WORKSHOP_DB.DEMO;
SHOW MODELS IN SCHEMA WORKSHOP_DB.DEMO;
SHOW TABLES LIKE 'TRANSACTIONS' IN SCHEMA WORKSHOP_DB.DEMO;
SHOW CORTEX SEARCH SERVICES IN SCHEMA WORKSHOP_DB.DEMO;

SELECT 'TEARDOWN COMPLETE - Ready for rebuild' AS STATUS;
