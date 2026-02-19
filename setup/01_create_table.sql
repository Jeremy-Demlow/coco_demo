-- ============================================================
-- 01_create_table.sql
-- Creates TRANSACTIONS table with fraud detection columns
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

CREATE OR REPLACE TABLE TRANSACTIONS (
    TRANSACTION_ID VARCHAR(20) NOT NULL,
    CUSTOMER_ID VARCHAR(20) NOT NULL,
    CUSTOMER_NAME VARCHAR(100),
    TRANSACTION_DATE DATE,
    TRANSACTION_TYPE VARCHAR(50),
    AMOUNT NUMBER(12,2),
    MERCHANT VARCHAR(100),
    CHANNEL VARCHAR(50),
    LOCATION VARCHAR(100),
    IS_FLAGGED BOOLEAN DEFAULT FALSE,
    IS_FRAUD BOOLEAN DEFAULT FALSE,
    NOTES_TEXT VARCHAR(16777216),
    
    PRIMARY KEY (TRANSACTION_ID)
);

COMMENT ON TABLE TRANSACTIONS IS 'Financial transactions with fraud detection and customer service notes';
COMMENT ON COLUMN TRANSACTIONS.IS_FLAGGED IS 'System flag for suspicious transactions';
COMMENT ON COLUMN TRANSACTIONS.IS_FRAUD IS 'Confirmed fraud indicator (TRUE = confirmed fraud)';
