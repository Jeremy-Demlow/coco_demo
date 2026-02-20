-- ============================================================
-- 03b_create_focus_semantic_view.sql
-- Creates semantic view for FOCUS billing data with Cortex Analyst
-- 
-- FOCUS-specific dimensions and metrics for FinOps analysis
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

CREATE OR REPLACE SEMANTIC VIEW COST_SEMANTIC_VIEW
    COMMENT = 'FOCUS-compliant cloud billing data for FinOps analysis'
AS
    -- Base table
    SELECT * FROM FOCUS_BILLING
    
    TABLES (
        FOCUS_BILLING
            COMMENT = 'Cloud billing data following FOCUS specification'
            PRIMARY KEY (RESOURCE_ID, CHARGE_PERIOD_START)
    )
    
    -- ============================================================
    -- DIMENSIONS - How to slice the data
    -- ============================================================
    DIMENSIONS (
        -- Time dimensions
        FOCUS_BILLING.CHARGE_PERIOD_START
            SYNONYMS = ('billing date', 'date', 'day', 'period')
            COMMENT = 'Date of the charge',
            
        FOCUS_BILLING.BILLING_PERIOD_START
            SYNONYMS = ('billing month', 'invoice period')
            COMMENT = 'Start of billing period (typically month)',
        
        -- Provider dimensions
        FOCUS_BILLING.PROVIDER_NAME
            SYNONYMS = ('cloud provider', 'cloud', 'provider', 'vendor')
            COMMENT = 'Cloud provider: AWS or Azure',
            
        FOCUS_BILLING.SERVICE_CATEGORY
            SYNONYMS = ('service type', 'category', 'service category')
            COMMENT = 'Service category: Compute, Storage, Networking, Databases, etc.',
            
        FOCUS_BILLING.SERVICE_NAME
            SYNONYMS = ('service', 'product', 'service name')
            COMMENT = 'Specific service: EC2, S3, Virtual Machines, etc.',
        
        -- Account dimensions
        FOCUS_BILLING.SUB_ACCOUNT_ID
            SYNONYMS = ('account id', 'account', 'linked account')
            COMMENT = 'AWS account ID or Azure subscription',
            
        FOCUS_BILLING.SUB_ACCOUNT_NAME
            SYNONYMS = ('account name', 'subscription name')
            COMMENT = 'Friendly name of the account',
        
        -- Location dimensions
        FOCUS_BILLING.REGION_ID
            SYNONYMS = ('region', 'location', 'region id')
            COMMENT = 'Cloud region: us-east-1, westus2, etc.',
            
        FOCUS_BILLING.REGION_NAME
            SYNONYMS = ('region name')
            COMMENT = 'Friendly region name',
            
        FOCUS_BILLING.AVAILABILITY_ZONE
            SYNONYMS = ('az', 'zone')
            COMMENT = 'Availability zone within region',
        
        -- Charge classification
        FOCUS_BILLING.CHARGE_CATEGORY
            SYNONYMS = ('charge type', 'charge category')
            COMMENT = 'Type of charge: Usage, Tax, or Credit',
            
        FOCUS_BILLING.PRICING_CATEGORY
            SYNONYMS = ('pricing type', 'pricing category', 'discount type')
            COMMENT = 'Pricing: Standard (on-demand), Committed (savings plan/reserved), Other',
        
        -- Commitment discount dimensions
        FOCUS_BILLING.COMMITMENT_DISCOUNT_TYPE
            SYNONYMS = ('commitment type', 'discount type', 'savings plan type')
            COMMENT = 'Type: Savings Plan or Reserved Instance',
            
        FOCUS_BILLING.COMMITMENT_DISCOUNT_STATUS
            SYNONYMS = ('commitment status', 'utilization status')
            COMMENT = 'Status: Used or Unused',
        
        -- Cost allocation (from tags)
        FOCUS_BILLING.X_DEPARTMENT
            SYNONYMS = ('department', 'team', 'cost center', 'business unit')
            COMMENT = 'Department for cost allocation',
            
        FOCUS_BILLING.X_ENVIRONMENT
            SYNONYMS = ('environment', 'env')
            COMMENT = 'Environment: Production, Development, Staging, Sandbox',
        
        -- Resource identification
        FOCUS_BILLING.RESOURCE_ID
            SYNONYMS = ('resource', 'arn', 'resource id')
            COMMENT = 'Unique resource identifier (ARN for AWS)',
            
        FOCUS_BILLING.RESOURCE_NAME
            SYNONYMS = ('resource name', 'instance name')
            COMMENT = 'Friendly name of the resource'
    )
    
    -- ============================================================
    -- METRICS - What to measure
    -- ============================================================
    METRICS (
        -- Primary cost metrics
        FOCUS_BILLING.BILLED_COST
            SYNONYMS = ('cost', 'spend', 'billed cost', 'invoice cost', 'charges')
            COMMENT = 'Amount billed/invoiced - what you pay'
            AGGREGATE = SUM,
            
        FOCUS_BILLING.EFFECTIVE_COST
            SYNONYMS = ('effective cost', 'amortized cost', 'true cost')
            COMMENT = 'Amortized cost including commitment spreading'
            AGGREGATE = SUM,
            
        FOCUS_BILLING.LIST_COST
            SYNONYMS = ('list cost', 'on demand cost', 'list price', 'retail cost')
            COMMENT = 'On-demand/retail price before discounts'
            AGGREGATE = SUM,
            
        FOCUS_BILLING.CONTRACTED_COST
            SYNONYMS = ('contracted cost', 'committed cost', 'reserved cost')
            COMMENT = 'Cost from committed/contracted pricing'
            AGGREGATE = SUM,
        
        -- Usage metrics
        FOCUS_BILLING.CONSUMED_QUANTITY
            SYNONYMS = ('usage', 'quantity', 'consumption', 'units')
            COMMENT = 'Amount of resource consumed'
            AGGREGATE = SUM,
        
        -- Commitment metrics
        FOCUS_BILLING.COMMITMENT_DISCOUNT_QUANTITY
            SYNONYMS = ('commitment amount', 'savings amount', 'discount amount')
            COMMENT = 'Amount of commitment discount applied'
            AGGREGATE = SUM
    );

-- Verify semantic view
DESCRIBE SEMANTIC VIEW COST_SEMANTIC_VIEW;

-- Test queries
SELECT 'Semantic view created - testing...' AS STATUS;

-- Test 1: Total cost by provider
SELECT CLOUD_PROVIDER, SUM(COST) AS TOTAL_COST
FROM BILLING_DATA
GROUP BY CLOUD_PROVIDER;

-- Test 2: Cost by service category
SELECT SERVICE_CATEGORY, SUM(COST) AS TOTAL_COST
FROM BILLING_DATA
GROUP BY SERVICE_CATEGORY
ORDER BY TOTAL_COST DESC;
