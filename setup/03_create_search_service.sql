-- ============================================================
-- 03_create_search_service.sql
-- Creates Cortex Search service for FinOps recommendations
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create recommendations table for FinOps insights
CREATE OR REPLACE TABLE COST_RECOMMENDATIONS (
    RECOMMENDATION_ID VARCHAR(20),
    CATEGORY VARCHAR(50),
    CLOUD_PROVIDER VARCHAR(10),
    SERVICE VARCHAR(50),
    TITLE VARCHAR(200),
    DESCRIPTION TEXT,
    POTENTIAL_SAVINGS VARCHAR(50),
    PRIORITY VARCHAR(20),
    CREATED_DATE DATE
);

-- Insert sample FinOps recommendations
INSERT INTO COST_RECOMMENDATIONS VALUES
-- AWS Recommendations
('REC-001', 'Rightsizing', 'AWS', 'EC2', 'Rightsize underutilized EC2 instances',
 'Analysis shows 23 EC2 instances with average CPU utilization below 10%. Consider downsizing from m5.xlarge to m5.large for these instances. This includes instances in the Engineering and Data Science departments running non-production workloads.',
 '$2,500/month', 'High', CURRENT_DATE()),

('REC-002', 'Reserved Instances', 'AWS', 'EC2', 'Purchase Reserved Instances for stable workloads',
 'Production EC2 instances have been running consistently for 8+ months. Converting 15 on-demand instances to 1-year Reserved Instances could reduce costs by up to 40%. Focus on us-east-1 region where most production workloads run.',
 '$4,200/month', 'High', CURRENT_DATE()),

('REC-003', 'Storage Optimization', 'AWS', 'S3', 'Implement S3 Intelligent-Tiering',
 'S3 buckets contain 45TB of data with infrequent access patterns. Moving to S3 Intelligent-Tiering will automatically optimize costs by moving data between access tiers. Estimated 30% reduction in storage costs.',
 '$800/month', 'Medium', CURRENT_DATE()),

('REC-004', 'Unused Resources', 'AWS', 'EC2', 'Terminate idle development instances',
 'Found 8 EC2 instances in Development environment that have been idle for over 30 days with no network traffic. These appear to be abandoned test instances. Recommend termination after verification with DevOps team.',
 '$1,100/month', 'High', CURRENT_DATE()),

('REC-005', 'Spot Instances', 'AWS', 'EC2', 'Use Spot Instances for batch processing',
 'Batch processing jobs in the Data Science department run nightly and can tolerate interruptions. Converting these workloads from on-demand to Spot Instances could reduce costs by up to 70%.',
 '$1,800/month', 'Medium', CURRENT_DATE()),

('REC-006', 'Lambda Optimization', 'AWS', 'Lambda', 'Optimize Lambda memory allocation',
 'Lambda functions are over-provisioned with 1024MB memory but only using 256MB on average. Right-sizing memory allocation will reduce costs proportionally. Review functions in the Platform team account.',
 '$300/month', 'Low', CURRENT_DATE()),

('REC-007', 'RDS Optimization', 'AWS', 'RDS', 'Use Aurora Serverless for variable workloads',
 'Development and QA RDS instances have highly variable usage patterns with long idle periods. Migrating to Aurora Serverless v2 would automatically scale capacity and reduce costs during low-usage periods.',
 '$900/month', 'Medium', CURRENT_DATE()),

-- Azure Recommendations
('REC-008', 'Rightsizing', 'Azure', 'Virtual Machines', 'Resize oversized Azure VMs',
 'Performance monitoring shows 12 Azure VMs in the westeurope region are oversized. Standard_D4s_v3 instances can be downsized to Standard_D2s_v3 without impacting performance based on 30-day utilization data.',
 '$1,600/month', 'High', CURRENT_DATE()),

('REC-009', 'Reserved Capacity', 'Azure', 'Virtual Machines', 'Purchase Azure Reserved VM Instances',
 'Stable production workloads on Azure have been running for 6+ months. Purchasing 1-year reserved capacity for 8 VMs in eastus region would provide 35% discount compared to pay-as-you-go pricing.',
 '$2,100/month', 'High', CURRENT_DATE()),

('REC-010', 'Storage Tiering', 'Azure', 'Blob Storage', 'Move cold data to Archive tier',
 'Azure Blob Storage contains 28TB of data not accessed in 90+ days. Moving this data from Hot tier to Archive tier would significantly reduce storage costs. Implement lifecycle management policies for automation.',
 '$650/month', 'Medium', CURRENT_DATE()),

('REC-011', 'Cosmos DB', 'Azure', 'Cosmos DB', 'Switch to autoscale throughput',
 'Cosmos DB containers are provisioned with fixed RU/s but show variable traffic patterns. Switching to autoscale throughput would optimize costs during low-traffic periods while handling peak loads.',
 '$400/month', 'Medium', CURRENT_DATE()),

('REC-012', 'Hybrid Benefit', 'Azure', 'Virtual Machines', 'Apply Azure Hybrid Benefit',
 'Organization has existing Windows Server and SQL Server licenses with Software Assurance. Applying Azure Hybrid Benefit to eligible VMs would reduce compute costs by up to 40%.',
 '$3,200/month', 'High', CURRENT_DATE()),

-- Cross-cloud recommendations
('REC-013', 'Anomaly Detection', 'AWS', 'EC2', 'Investigate recent cost spike in us-west-2',
 'EC2 costs in us-west-2 increased by 47% last week compared to the 30-day average. Investigation shows new instances launched by the Security team. Verify these are expected and properly tagged.',
 'Investigation', 'High', CURRENT_DATE()),

('REC-014', 'Tagging', 'AWS', 'Multiple', 'Improve resource tagging coverage',
 'Only 68% of AWS resources have proper cost allocation tags. Implementing mandatory tagging for Department, Environment, and Project tags will improve cost visibility and enable better chargeback.',
 'Visibility', 'Medium', CURRENT_DATE()),

('REC-015', 'Budget Alerts', 'Azure', 'Multiple', 'Set up budget alerts for all departments',
 'Budget alerts are only configured for 3 of 5 departments. Setting up alerts at 50%, 75%, and 90% thresholds will provide early warning of potential overruns and enable proactive cost management.',
 'Prevention', 'Medium', CURRENT_DATE());

-- Create Cortex Search service on recommendations
CREATE OR REPLACE CORTEX SEARCH SERVICE TEXT_SEARCH
    ON DESCRIPTION
    ATTRIBUTES CATEGORY, CLOUD_PROVIDER, SERVICE, PRIORITY, POTENTIAL_SAVINGS
    WAREHOUSE = WORKSHOP_WH
    TARGET_LAG = '1 hour'
    AS (
        SELECT 
            RECOMMENDATION_ID,
            CATEGORY,
            CLOUD_PROVIDER,
            SERVICE,
            TITLE,
            DESCRIPTION,
            POTENTIAL_SAVINGS,
            PRIORITY
        FROM COST_RECOMMENDATIONS
    );

-- Verify search service created
SHOW CORTEX SEARCH SERVICES;
