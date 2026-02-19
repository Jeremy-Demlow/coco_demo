-- ============================================================
-- 05_grants.sql
-- Grants permissions for demo users to access all objects
-- 
-- Adjust role as needed (PUBLIC grants to all users)
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- Database and schema access
GRANT USAGE ON DATABASE WORKSHOP_DB TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA WORKSHOP_DB.DEMO TO ROLE PUBLIC;

-- Warehouse access (required for agent to execute queries)
GRANT USAGE ON WAREHOUSE WORKSHOP_WH TO ROLE PUBLIC;

-- Table access
GRANT SELECT ON TABLE WORKSHOP_DB.DEMO.TRANSACTIONS TO ROLE PUBLIC;

-- Cortex Search Service access
GRANT USAGE ON CORTEX SEARCH SERVICE WORKSHOP_DB.DEMO.TEXT_SEARCH TO ROLE PUBLIC;

-- Semantic View access
GRANT SELECT, REFERENCES ON SEMANTIC VIEW WORKSHOP_DB.DEMO.DEMO_SEMANTIC_VIEW TO ROLE PUBLIC;

-- Agent access
GRANT USAGE ON AGENT WORKSHOP_DB.DEMO.DEMO_AGENT TO ROLE PUBLIC;

-- Optional: Grant to specific role instead of PUBLIC
-- GRANT USAGE ON AGENT WORKSHOP_DB.DEMO.DEMO_AGENT TO ROLE DEMO_USER_ROLE;
