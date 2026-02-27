-- ============================================================================
-- RECONCILIATION 360 DATA MODEL - EXPLORATION QUERIES
-- ============================================================================
-- Use these queries to understand the entity_360 and reconciliation_fact tables
-- Database: DBAPI_REPLICA_DB | Schema: PUBLIC_MARTS
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE DBAPI_REPLICA_DB;
USE SCHEMA PUBLIC_MARTS;

-- ============================================================================
-- SECTION 1: DATA OVERVIEW
-- ============================================================================

-- 1.1 Row counts for mart tables
SELECT 'entity_360' AS table_name, COUNT(*) AS row_count FROM entity_360
UNION ALL
SELECT 'reconciliation_fact', COUNT(*) FROM reconciliation_fact;

-- 1.2 Entity 360 sample - see what columns are available
SELECT * FROM entity_360 LIMIT 10;

-- 1.3 Reconciliation Fact sample
SELECT * FROM reconciliation_fact LIMIT 10;

-- ============================================================================
-- SECTION 2: ENTITY 360 - KEY INSIGHTS
-- ============================================================================

-- 2.1 Total entities and periods covered
SELECT 
    COUNT(DISTINCT entity_id) AS total_entities,
    COUNT(DISTINCT entity_name) AS unique_entity_names,
    COUNT(DISTINCT period_id) AS total_periods,
    MIN(period_end_date) AS earliest_period,
    MAX(period_end_date) AS latest_period
FROM entity_360;

-- 2.2 Risk distribution - how many entities by risk level?
SELECT 
    variance_risk_level,
    COUNT(*) AS entity_period_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM entity_360
GROUP BY variance_risk_level
ORDER BY entity_period_count DESC;

-- 2.3 Top 10 entities by total GL balance (most recent period)
SELECT 
    entity_name,
    entity_code,
    period_end_date,
    total_gl_balance,
    total_bank_balance,
    total_variance,
    variance_risk_level
FROM entity_360
WHERE period_end_date = (SELECT MAX(period_end_date) FROM entity_360)
ORDER BY total_gl_balance DESC
LIMIT 10;

-- 2.4 High risk entities - what's driving the risk?
SELECT 
    entity_name,
    entity_code,
    period_year,
    period_quarter,
    total_assignments,
    variance_count,
    total_variance,
    total_absolute_variance,
    max_single_variance
FROM entity_360
WHERE variance_risk_level = 'High Risk'
ORDER BY total_absolute_variance DESC
LIMIT 20;

-- 2.5 Quarterly summary across all entities
SELECT 
    period_year,
    period_quarter,
    COUNT(DISTINCT entity_id) AS entities,
    SUM(total_assignments) AS total_assignments,
    SUM(total_gl_balance) AS sum_gl_balance,
    SUM(total_variance) AS sum_variance,
    SUM(variance_count) AS total_variances,
    SUM(CASE WHEN variance_risk_level = 'High Risk' THEN 1 ELSE 0 END) AS high_risk_count
FROM entity_360
GROUP BY period_year, period_quarter
ORDER BY period_year, period_quarter;

-- ============================================================================
-- SECTION 3: RECONCILIATION FACT - DETAILED ANALYSIS
-- ============================================================================

-- 3.1 Reconciliation status distribution
SELECT 
    reconciliation_status,
    COUNT(*) AS recon_count,
    SUM(balance_bank) AS total_bank_balance,
    SUM(ABS(bank_calc_diff)) AS total_difference,
    AVG(ABS(bank_calc_diff)) AS avg_difference
FROM reconciliation_fact
GROUP BY reconciliation_status
ORDER BY recon_count DESC;

-- 3.2 Top entities with most "Needs Review" reconciliations
SELECT 
    entity_name,
    entity_code,
    COUNT(*) AS needs_review_count,
    SUM(ABS(bank_calc_diff)) AS total_difference
FROM reconciliation_fact
WHERE reconciliation_status = 'Needs Review'
GROUP BY entity_name, entity_code
ORDER BY needs_review_count DESC
LIMIT 15;

-- 3.3 Reconciliations by currency
SELECT 
    currency,
    COUNT(*) AS recon_count,
    SUM(balance_bank) AS total_bank_balance,
    AVG(balance_bank) AS avg_bank_balance
FROM reconciliation_fact
WHERE currency IS NOT NULL
GROUP BY currency
ORDER BY recon_count DESC;

-- 3.4 Monthly reconciliation volume and status
SELECT 
    period_year,
    period_month_num,
    COUNT(*) AS total_recons,
    SUM(CASE WHEN reconciliation_status = 'Reconciled' THEN 1 ELSE 0 END) AS reconciled,
    SUM(CASE WHEN reconciliation_status = 'Needs Review' THEN 1 ELSE 0 END) AS needs_review,
    ROUND(SUM(CASE WHEN reconciliation_status = 'Reconciled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS reconciled_pct
FROM reconciliation_fact
GROUP BY period_year, period_month_num
ORDER BY period_year, period_month_num;

-- 3.5 Largest unreconciled differences
SELECT 
    reconciliation_id,
    entity_name,
    account_combination,
    period_end_date,
    balance_bank,
    balance_calculated,
    bank_calc_diff,
    reconciliation_status
FROM reconciliation_fact
WHERE reconciliation_status = 'Needs Review'
ORDER BY ABS(bank_calc_diff) DESC
LIMIT 20;

-- ============================================================================
-- SECTION 4: TREND ANALYSIS
-- ============================================================================

-- 4.1 Variance trend over time
SELECT 
    period_end_date,
    SUM(total_variance) AS sum_variance,
    SUM(total_absolute_variance) AS sum_abs_variance,
    AVG(total_variance) AS avg_variance,
    COUNT(DISTINCT entity_id) AS entity_count
FROM entity_360
GROUP BY period_end_date
ORDER BY period_end_date;

-- 4.2 Entity activity trend - are entities getting more active?
SELECT 
    period_year,
    period_quarter,
    AVG(active_assignment_pct) AS avg_active_pct,
    AVG(activity_coverage_pct) AS avg_activity_coverage,
    SUM(active_assignments) AS total_active,
    SUM(total_assignments) AS total_assignments
FROM entity_360
GROUP BY period_year, period_quarter
ORDER BY period_year, period_quarter;

-- ============================================================================
-- SECTION 5: ENTITY HIERARCHY ANALYSIS
-- ============================================================================

-- 5.1 Parent entities with most child reconciliations
SELECT 
    entity_parent_name,
    COUNT(DISTINCT entity_name) AS child_entities,
    COUNT(*) AS total_reconciliations,
    SUM(balance_bank) AS total_bank_balance
FROM reconciliation_fact
WHERE entity_parent_name IS NOT NULL
GROUP BY entity_parent_name
ORDER BY total_reconciliations DESC
LIMIT 15;

-- ============================================================================
-- SECTION 6: DATA QUALITY CHECKS
-- ============================================================================

-- 6.1 Check for null values in key fields
SELECT 
    'entity_360' AS table_name,
    SUM(CASE WHEN entity_id IS NULL THEN 1 ELSE 0 END) AS null_entity_id,
    SUM(CASE WHEN period_id IS NULL THEN 1 ELSE 0 END) AS null_period_id,
    SUM(CASE WHEN total_gl_balance IS NULL THEN 1 ELSE 0 END) AS null_gl_balance
FROM entity_360
UNION ALL
SELECT 
    'reconciliation_fact',
    SUM(CASE WHEN entity_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN period_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN balance_bank IS NULL THEN 1 ELSE 0 END)
FROM reconciliation_fact;

-- 6.2 Period coverage check - are all periods represented?
SELECT 
    period_year,
    LISTAGG(DISTINCT period_month_num, ', ') WITHIN GROUP (ORDER BY period_month_num) AS months_present,
    COUNT(DISTINCT period_month_num) AS month_count
FROM entity_360
GROUP BY period_year
ORDER BY period_year;


USE ROLE ACCOUNTADMIN;

-- Then run:
CREATE DBT PROJECT "DBAPI_REPLICA_DB"."DBT_PROJECTS"."COCO_DBT_PROJECT_TEST" 
FROM $$snow://workspace/USER$JDEMLOW.PUBLIC."coco_demo"/versions/live/coco_demo$$ 
DEFAULT_TARGET = 'dev' 
DBT_VERSION = '1.9.4';