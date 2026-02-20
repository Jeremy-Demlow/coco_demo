-- ============================================================
-- 02_load_focus_data.sql
-- Loads FOCUS billing data from parquet file
-- 
-- Prerequisites: 
--   1. Run 01_create_focus_table.sql first
--   2. Upload focus_billing_data.parquet to a stage
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create stage for data files
CREATE STAGE IF NOT EXISTS BILLING_STAGE
    DIRECTORY = (ENABLE = TRUE);

-- To upload the parquet file, run this from CLI:
-- snow stage copy data/focus_billing_data.parquet @WORKSHOP_DB.DEMO.BILLING_STAGE

-- Load data from parquet using MATCH_BY_COLUMN_NAME
COPY INTO FOCUS_BILLING
FROM @BILLING_STAGE/focus_billing_data.parquet
FILE_FORMAT = (TYPE = PARQUET)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = CONTINUE;

-- Verify load
SELECT 
    COUNT(*) AS total_rows,
    MIN(CHARGE_PERIOD_START) AS start_date,
    MAX(CHARGE_PERIOD_START) AS end_date,
    COUNT(DISTINCT PROVIDER_NAME) AS providers,
    COUNT(DISTINCT SERVICE_NAME) AS services,
    SUM(BILLED_COST) AS total_billed_cost
FROM FOCUS_BILLING;

-- Sample data
SELECT * FROM FOCUS_BILLING LIMIT 5;

-- Summary by provider
SELECT 
    PROVIDER_NAME,
    COUNT(*) AS rows,
    SUM(BILLED_COST) AS billed_cost,
    SUM(EFFECTIVE_COST) AS effective_cost
FROM FOCUS_BILLING
GROUP BY PROVIDER_NAME;

-- Summary by service category
SELECT 
    SERVICE_CATEGORY,
    COUNT(*) AS rows,
    SUM(BILLED_COST) AS billed_cost
FROM FOCUS_BILLING
GROUP BY SERVICE_CATEGORY
ORDER BY billed_cost DESC;
