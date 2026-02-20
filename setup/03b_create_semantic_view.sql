-- ============================================================
-- 03b_create_semantic_view.sql
-- Creates a Cortex Analyst semantic view for cloud cost analytics
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create the semantic view for cost analytics
CREATE OR REPLACE SEMANTIC VIEW DEMO_SEMANTIC_VIEW
  TABLES (BILLING_DATA)
  COMMENT = 'Semantic model for cloud billing cost analytics and forecasting'
AS
$$
name: Cloud Cost Analytics
tables:
  - name: BILLING_DATA
    description: >
      Daily cloud billing records from AWS and Azure. Contains cost and usage data
      broken down by service, region, account, department, and environment.
      Use this table for cost analysis, trend identification, and budget tracking.
    base_table:
      database: WORKSHOP_DB
      schema: DEMO
      table: BILLING_DATA
    
    dimensions:
      - name: billing_date
        expr: BILLING_DATE
        data_type: DATE
        description: The date of the billing record
        sample_values:
          - "2024-01-15"
          - "2024-06-30"
          - "2024-12-01"
        
      - name: cloud_provider
        expr: CLOUD_PROVIDER
        data_type: VARCHAR
        description: Cloud provider (AWS or Azure)
        sample_values:
          - "AWS"
          - "Azure"
          
      - name: account_id
        expr: ACCOUNT_ID
        data_type: VARCHAR
        description: Unique identifier for the cloud account
        sample_values:
          - "AWS-001"
          - "AZU-011"
          
      - name: account_name
        expr: ACCOUNT_NAME
        data_type: VARCHAR
        description: Human-readable name of the cloud account
        
      - name: service
        expr: SERVICE
        data_type: VARCHAR
        description: >
          Cloud service name (e.g., EC2, S3, Lambda for AWS; 
          Virtual Machines, Blob Storage, Functions for Azure)
        sample_values:
          - "EC2"
          - "S3"
          - "Virtual Machines"
          - "Blob Storage"
          
      - name: region
        expr: REGION
        data_type: VARCHAR
        description: Cloud region where the resource is deployed
        sample_values:
          - "us-east-1"
          - "eu-west-1"
          - "eastus"
          - "westeurope"
          
      - name: department
        expr: DEPARTMENT
        data_type: VARCHAR
        description: Business department responsible for the cost
        sample_values:
          - "Engineering"
          - "Data Science"
          - "Platform"
          - "DevOps"
          
      - name: environment
        expr: ENVIRONMENT
        data_type: VARCHAR
        description: Deployment environment
        sample_values:
          - "Production"
          - "Staging"
          - "Development"
          - "QA"
    
    time_dimensions:
      - name: billing_month
        expr: DATE_TRUNC('MONTH', BILLING_DATE)
        data_type: DATE
        description: Month of the billing record for monthly aggregations
        
      - name: billing_quarter
        expr: DATE_TRUNC('QUARTER', BILLING_DATE)
        data_type: DATE
        description: Quarter of the billing record for quarterly aggregations
        
      - name: billing_year
        expr: DATE_TRUNC('YEAR', BILLING_DATE)
        data_type: DATE
        description: Year of the billing record for annual aggregations
    
    measures:
      - name: total_cost
        expr: SUM(COST)
        data_type: NUMBER
        description: Total cost in dollars
        
      - name: average_daily_cost
        expr: AVG(COST)
        data_type: NUMBER
        description: Average daily cost per record
        
      - name: total_usage
        expr: SUM(USAGE_QUANTITY)
        data_type: NUMBER
        description: Total usage quantity
        
      - name: record_count
        expr: COUNT(*)
        data_type: NUMBER
        description: Number of billing records
        
      - name: unique_services
        expr: COUNT(DISTINCT SERVICE)
        data_type: NUMBER
        description: Number of unique services used
        
      - name: unique_accounts
        expr: COUNT(DISTINCT ACCOUNT_ID)
        data_type: NUMBER
        description: Number of unique accounts
        
      - name: max_daily_cost
        expr: MAX(COST)
        data_type: NUMBER
        description: Maximum single-day cost

verified_queries:
  - name: "Monthly cost by cloud provider"
    question: "What is the monthly cost breakdown by cloud provider?"
    sql: |
      SELECT 
        DATE_TRUNC('MONTH', BILLING_DATE) AS month,
        CLOUD_PROVIDER,
        SUM(COST) AS total_cost
      FROM BILLING_DATA
      GROUP BY 1, 2
      ORDER BY 1, 2
    verified_at: 1700000000
    verified_by: demo
    
  - name: "Top services by cost"
    question: "Which services cost the most?"
    sql: |
      SELECT 
        SERVICE,
        SUM(COST) AS total_cost
      FROM BILLING_DATA
      GROUP BY SERVICE
      ORDER BY total_cost DESC
      LIMIT 10
    verified_at: 1700000000
    verified_by: demo
    
  - name: "Cost by department"
    question: "How much does each department spend?"
    sql: |
      SELECT 
        DEPARTMENT,
        SUM(COST) AS total_cost
      FROM BILLING_DATA
      GROUP BY DEPARTMENT
      ORDER BY total_cost DESC
    verified_at: 1700000000
    verified_by: demo
    
  - name: "Daily cost trend"
    question: "What is the daily cost trend over time?"
    sql: |
      SELECT 
        BILLING_DATE,
        SUM(COST) AS daily_cost
      FROM BILLING_DATA
      GROUP BY BILLING_DATE
      ORDER BY BILLING_DATE
    verified_at: 1700000000
    verified_by: demo
    
  - name: "Production vs non-production costs"
    question: "How do production costs compare to non-production?"
    sql: |
      SELECT 
        CASE WHEN ENVIRONMENT = 'Production' THEN 'Production' ELSE 'Non-Production' END AS env_type,
        SUM(COST) AS total_cost
      FROM BILLING_DATA
      GROUP BY 1
    verified_at: 1700000000
    verified_by: demo
$$;

-- Verify semantic view created
SHOW SEMANTIC VIEWS;
