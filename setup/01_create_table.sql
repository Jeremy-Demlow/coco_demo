-- ============================================================
-- 01_create_table.sql
-- Creates the BILLING_DATA table for cloud cost analytics
-- ============================================================

USE ROLE SYSADMIN;

-- Create warehouse if not exists
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Create database and schema
CREATE DATABASE IF NOT EXISTS WORKSHOP_DB;
CREATE SCHEMA IF NOT EXISTS WORKSHOP_DB.DEMO;

USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create billing data table
CREATE OR REPLACE TABLE BILLING_DATA (
    BILLING_DATE DATE,
    CLOUD_PROVIDER VARCHAR(10),
    ACCOUNT_ID VARCHAR(20),
    ACCOUNT_NAME VARCHAR(100),
    SERVICE VARCHAR(50),
    REGION VARCHAR(30),
    DEPARTMENT VARCHAR(50),
    ENVIRONMENT VARCHAR(20),
    USAGE_QUANTITY NUMBER(18,2),
    COST NUMBER(18,2)
);

-- Verify table created
DESCRIBE TABLE BILLING_DATA;
