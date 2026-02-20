-- ============================================================
-- 01_create_focus_table.sql
-- Creates FOCUS-compliant billing table
-- 
-- FOCUS = FinOps Open Cost and Usage Specification
-- https://focus.finops.org/
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Drop old simplified table if exists
DROP TABLE IF EXISTS BILLING_DATA;

-- Create FOCUS-compliant billing table
CREATE OR REPLACE TABLE FOCUS_BILLING (
    -- Time periods
    BILLING_PERIOD_START        TIMESTAMP_TZ,
    BILLING_PERIOD_END          TIMESTAMP_TZ,
    CHARGE_PERIOD_START         TIMESTAMP_TZ,
    CHARGE_PERIOD_END           TIMESTAMP_TZ,
    
    -- Cost columns (4 types per FOCUS spec)
    BILLED_COST                 NUMBER(18,6),      -- What you're invoiced
    EFFECTIVE_COST              NUMBER(18,6),      -- Amortized cost
    LIST_COST                   NUMBER(18,6),      -- On-demand price
    CONTRACTED_COST             NUMBER(18,6),      -- Committed/negotiated price
    
    -- Provider and service
    PROVIDER_NAME               VARCHAR(50),       -- AWS, Azure, GCP
    PUBLISHER_NAME              VARCHAR(100),
    INVOICE_ISSUER_NAME         VARCHAR(100),
    SERVICE_CATEGORY            VARCHAR(50),       -- Compute, Storage, Networking, etc.
    SERVICE_NAME                VARCHAR(100),      -- EC2, S3, Virtual Machines, etc.
    
    -- Account hierarchy
    BILLING_ACCOUNT_ID          VARCHAR(50),
    BILLING_ACCOUNT_NAME        VARCHAR(100),
    BILLING_ACCOUNT_TYPE        VARCHAR(20),
    SUB_ACCOUNT_ID              VARCHAR(50),
    SUB_ACCOUNT_NAME            VARCHAR(100),
    SUB_ACCOUNT_TYPE            VARCHAR(20),
    
    -- Location
    REGION_ID                   VARCHAR(30),
    REGION_NAME                 VARCHAR(50),
    AVAILABILITY_ZONE           VARCHAR(30),
    
    -- Charge classification
    CHARGE_CATEGORY             VARCHAR(20),       -- Usage, Tax, Credit
    CHARGE_CLASS                VARCHAR(20),
    CHARGE_DESCRIPTION          VARCHAR(500),
    CHARGE_FREQUENCY            VARCHAR(30),
    PRICING_CATEGORY            VARCHAR(20),       -- Standard, Committed, Other
    
    -- Currency
    BILLING_CURRENCY            VARCHAR(10),
    PRICING_CURRENCY            VARCHAR(10),
    
    -- Commitment discounts (Savings Plans, Reserved Instances)
    COMMITMENT_DISCOUNT_CATEGORY    VARCHAR(30),
    COMMITMENT_DISCOUNT_ID          VARCHAR(200),
    COMMITMENT_DISCOUNT_NAME        VARCHAR(100),
    COMMITMENT_DISCOUNT_TYPE        VARCHAR(50),   -- Savings Plan, Reserved
    COMMITMENT_DISCOUNT_STATUS      VARCHAR(20),   -- Used, Unused
    COMMITMENT_DISCOUNT_QUANTITY    NUMBER(18,6),
    COMMITMENT_DISCOUNT_UNIT        VARCHAR(20),
    
    -- Usage metrics
    CONSUMED_QUANTITY           NUMBER(18,6),
    CONSUMED_UNIT               VARCHAR(30),
    PRICING_QUANTITY            NUMBER(18,6),
    PRICING_UNIT                VARCHAR(30),
    LIST_UNIT_PRICE             NUMBER(18,8),
    CONTRACTED_UNIT_PRICE       NUMBER(18,8),
    
    -- Resource identification
    RESOURCE_ID                 VARCHAR(500),      -- ARN or Azure resource ID
    RESOURCE_NAME               VARCHAR(200),
    RESOURCE_TYPE               VARCHAR(100),
    
    -- Tags (for cost allocation)
    TAGS                        VARIANT,           -- Array of key-value pairs
    
    -- SKU information
    SKU_ID                      VARCHAR(50),
    SKU_METER                   VARCHAR(100),
    SKU_PRICE_ID                VARCHAR(50),
    
    -- Custom extensions (x_ prefix per FOCUS spec)
    X_DEPARTMENT                VARCHAR(50),       -- Cost allocation
    X_ENVIRONMENT               VARCHAR(30),       -- Production, Development, etc.
    X_SERVICE_CODE              VARCHAR(100)
);

-- Create view with common column aliases for easier querying
CREATE OR REPLACE VIEW BILLING_DATA AS
SELECT
    CHARGE_PERIOD_START AS BILLING_DATE,
    PROVIDER_NAME AS CLOUD_PROVIDER,
    SUB_ACCOUNT_ID AS ACCOUNT_ID,
    SUB_ACCOUNT_NAME AS ACCOUNT_NAME,
    SERVICE_NAME AS SERVICE,
    SERVICE_CATEGORY,
    REGION_ID AS REGION,
    REGION_NAME,
    X_DEPARTMENT AS DEPARTMENT,
    X_ENVIRONMENT AS ENVIRONMENT,
    CONSUMED_QUANTITY AS USAGE_QUANTITY,
    BILLED_COST AS COST,
    EFFECTIVE_COST,
    LIST_COST,
    CHARGE_CATEGORY,
    PRICING_CATEGORY,
    COMMITMENT_DISCOUNT_TYPE,
    COMMITMENT_DISCOUNT_STATUS,
    TAGS
FROM FOCUS_BILLING;

-- Verify
SELECT 'FOCUS_BILLING table created' AS STATUS;
DESCRIBE TABLE FOCUS_BILLING;
