-- ============================================================
-- 03_create_search_service.sql
-- Creates Cortex Search Service for searching transaction notes
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

CREATE OR REPLACE CORTEX SEARCH SERVICE TEXT_SEARCH
    ON NOTES_TEXT
    WAREHOUSE = WORKSHOP_WH
    TARGET_LAG = '1 hour'
AS (
    SELECT
        TRANSACTION_ID,
        CUSTOMER_ID,
        CUSTOMER_NAME,
        TRANSACTION_DATE,
        TRANSACTION_TYPE,
        AMOUNT,
        MERCHANT,
        CHANNEL,
        LOCATION,
        IS_FLAGGED,
        IS_FRAUD,
        NOTES_TEXT
    FROM TRANSACTIONS
);

-- Verify search service was created
SHOW CORTEX SEARCH SERVICES LIKE 'TEXT_SEARCH' IN SCHEMA DEMO;
