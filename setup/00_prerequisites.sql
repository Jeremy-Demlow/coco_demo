-- ============================================================
-- 00_prerequisites.sql
-- Creates all infrastructure needed before running other scripts
-- 
-- RUN THIS FIRST on a fresh Snowflake account!
-- ============================================================

USE ROLE SYSADMIN;

-- Create warehouse for compute
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL' 
    AUTO_SUSPEND = 60 
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for fraud detection demo';

-- Create database and schema
CREATE DATABASE IF NOT EXISTS WORKSHOP_DB
    COMMENT = 'Database for fraud detection demo';

CREATE SCHEMA IF NOT EXISTS WORKSHOP_DB.DEMO
    COMMENT = 'Schema for fraud detection demo objects';

-- Set context for subsequent scripts
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;
USE WAREHOUSE WORKSHOP_WH;

-- Create stage for data loading
CREATE STAGE IF NOT EXISTS DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for uploading transaction data CSV';

-- Verify creation
SHOW WAREHOUSES LIKE 'WORKSHOP_WH';
SHOW DATABASES LIKE 'WORKSHOP_DB';
SHOW SCHEMAS LIKE 'DEMO' IN DATABASE WORKSHOP_DB;
SHOW STAGES LIKE 'DATA_STAGE' IN SCHEMA WORKSHOP_DB.DEMO;

SELECT 'Prerequisites created successfully!' AS STATUS;
