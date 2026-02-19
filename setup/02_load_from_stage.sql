-- ============================================================
-- 02_load_from_stage.sql
-- Creates stage, file format, and loads transaction data
-- 
-- Prerequisites:
-- 1. Generate data (if not already done):
--    cd data && python generate_data.py
--
-- 2. Upload CSV to Snowflake stage:
--    snow stage copy data/transactions_100k.csv @WORKSHOP_DB.DEMO.DATA_STAGE --connection myconnection
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create stage for data files
CREATE STAGE IF NOT EXISTS DATA_STAGE;

-- Create CSV file format
CREATE OR REPLACE FILE FORMAT CSVFORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '');

-- Load data from stage
COPY INTO TRANSACTIONS
FROM @DATA_STAGE/transactions_100k.csv
FILE_FORMAT = CSVFORMAT
ON_ERROR = 'CONTINUE';

-- Verify data loaded
SELECT COUNT(*) AS row_count FROM TRANSACTIONS;
