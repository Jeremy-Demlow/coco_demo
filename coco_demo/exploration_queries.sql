-- ============================================================================
-- RECONCILIATION 360 DATA MODEL - EXPLORATION QUERIES
-- ============================================================================
-- This file contains helpful queries to understand the Entity 360 and 
-- Assignment 360 data models created in COCO_LIVE_DB.DBT_MARTS
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATA OVERVIEW
-- ============================================================================

-- 1.1 Row counts for all marts
SELECT 'ENTITY_360' AS table_name, COUNT(*) AS row_count FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360
UNION ALL
SELECT 'ASSIGNMENT_360', COUNT(*) FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360;

-- 1.2 Entity 360 - Column overview with sample values
SELECT * FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360 LIMIT 10;

-- 1.3 Assignment 360 - Column overview with sample values
SELECT * FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360 LIMIT 10;

-- ============================================================================
-- SECTION 2: ENTITY 360 INSIGHTS
-- ============================================================================

-- 2.1 Entity summary statistics
SELECT
    COUNT(DISTINCT entity_id) AS total_entities,
    COUNT(DISTINCT period_id) AS total_periods,
    MIN(period_end_date) AS earliest_period,
    MAX(period_end_date) AS latest_period,
    AVG(total_assignments) AS avg_assignments_per_entity,
    SUM(total_variance) AS total_variance_all
FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360;

-- 2.2 Top 10 entities by total variance (highest risk)
SELECT 
    entity_name,
    entity_code,
    SUM(total_variance) AS total_variance,
    AVG(assignment_completion_rate) AS avg_completion_rate,
    COUNT(DISTINCT period_id) AS periods_tracked
FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360
GROUP BY entity_name, entity_code
ORDER BY total_variance DESC
LIMIT 10;

-- 2.3 Variance risk distribution across entities
SELECT 
    variance_risk_level,
    COUNT(*) AS record_count,
    COUNT(DISTINCT entity_id) AS unique_entities,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360
GROUP BY variance_risk_level
ORDER BY record_count DESC;

-- 2.4 Period-over-period variance trends
SELECT 
    period_end_date,
    period_year,
    period_quarter,
    COUNT(DISTINCT entity_id) AS entities_with_data,
    SUM(total_variance) AS total_variance,
    SUM(total_unreconciled_amount) AS total_unreconciled,
    AVG(assignment_completion_rate) AS avg_completion_rate
FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360
GROUP BY period_end_date, period_year, period_quarter
ORDER BY period_end_date;

-- 2.5 Entities with declining completion rates (potential issues)
WITH entity_trends AS (
    SELECT 
        entity_name,
        period_end_date,
        assignment_completion_rate,
        LAG(assignment_completion_rate) OVER (PARTITION BY entity_id ORDER BY period_end_date) AS prev_completion_rate
    FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360
)
SELECT 
    entity_name,
    period_end_date,
    assignment_completion_rate,
    prev_completion_rate,
    assignment_completion_rate - prev_completion_rate AS change
FROM entity_trends
WHERE prev_completion_rate IS NOT NULL
  AND assignment_completion_rate < prev_completion_rate
ORDER BY change ASC
LIMIT 20;

-- ============================================================================
-- SECTION 3: ASSIGNMENT 360 INSIGHTS
-- ============================================================================

-- 3.1 Assignment summary statistics
SELECT
    COUNT(DISTINCT assignment_id) AS total_assignments,
    COUNT(DISTINCT entity_id) AS total_entities,
    COUNT(DISTINCT currency) AS currencies_used,
    SUM(balance_gl) AS total_gl_balance,
    SUM(balance_bank) AS total_bank_balance,
    SUM(total_variance) AS total_variance
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360;

-- 3.2 Assignment type distribution
SELECT 
    assignment_type,
    COUNT(DISTINCT assignment_id) AS unique_assignments,
    COUNT(*) AS total_records,
    AVG(balance_gl) AS avg_gl_balance,
    SUM(total_variance) AS total_variance
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360
GROUP BY assignment_type
ORDER BY unique_assignments DESC;

-- 3.3 Reconciliation status breakdown
SELECT 
    reconciliation_status,
    COUNT(*) AS record_count,
    COUNT(DISTINCT assignment_id) AS unique_assignments,
    SUM(unreconciled_amount) AS total_unreconciled,
    AVG(total_variance) AS avg_variance
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360
GROUP BY reconciliation_status
ORDER BY record_count DESC;

-- 3.4 Top 20 assignments needing review (highest unreconciled amounts)
SELECT 
    assignment_id,
    entity_name,
    combo_name,
    assignment_type,
    currency,
    period_end_date,
    unreconciled_amount,
    total_variance,
    variance_risk,
    reconciliation_status
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360
WHERE reconciliation_status = 'Needs Review'
ORDER BY unreconciled_amount DESC
LIMIT 20;

-- 3.5 High variance assignments by entity
SELECT 
    entity_name,
    COUNT(*) AS high_variance_count,
    SUM(total_variance) AS total_high_variance,
    AVG(total_variance) AS avg_variance
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360
WHERE variance_risk = 'High'
GROUP BY entity_name
ORDER BY total_high_variance DESC
LIMIT 15;

-- 3.6 Currency distribution analysis
SELECT 
    currency,
    COUNT(DISTINCT assignment_id) AS assignments,
    COUNT(DISTINCT entity_id) AS entities,
    SUM(balance_gl) AS total_gl,
    SUM(balance_bank) AS total_bank,
    SUM(total_variance) AS total_variance
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360
WHERE currency IS NOT NULL
GROUP BY currency
ORDER BY assignments DESC;

-- ============================================================================
-- SECTION 4: CROSS-MODEL ANALYSIS
-- ============================================================================

-- 4.1 Entity health scorecard (combines multiple metrics)
SELECT 
    entity_name,
    entity_code,
    COUNT(DISTINCT a.period_id) AS periods_active,
    COUNT(DISTINCT a.assignment_id) AS total_assignments,
    SUM(CASE WHEN a.variance_risk = 'High' THEN 1 ELSE 0 END) AS high_risk_count,
    SUM(CASE WHEN a.reconciliation_status = 'Needs Review' THEN 1 ELSE 0 END) AS needs_review_count,
    AVG(a.total_variance) AS avg_variance,
    SUM(a.unreconciled_amount) AS total_unreconciled,
    CASE 
        WHEN SUM(CASE WHEN a.variance_risk = 'High' THEN 1 ELSE 0 END) > 100 THEN 'Critical'
        WHEN SUM(CASE WHEN a.reconciliation_status = 'Needs Review' THEN 1 ELSE 0 END) > 50 THEN 'At Risk'
        ELSE 'Healthy'
    END AS health_status
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360 a
GROUP BY entity_name, entity_code
ORDER BY high_risk_count DESC
LIMIT 20;

-- 4.2 Monthly reconciliation performance
SELECT 
    period_year,
    period_month_num,
    COUNT(DISTINCT entity_id) AS entities,
    COUNT(DISTINCT assignment_id) AS assignments,
    SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS active_count,
    SUM(CASE WHEN reconciliation_status = 'Complete' THEN 1 ELSE 0 END) AS completed_count,
    ROUND(SUM(CASE WHEN reconciliation_status = 'Complete' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_pct,
    SUM(total_variance) AS total_variance
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360
GROUP BY period_year, period_month_num
ORDER BY period_year, period_month_num;

-- 4.3 Segment analysis (account segments)
SELECT 
    segment1,
    segment2,
    COUNT(DISTINCT assignment_id) AS assignments,
    SUM(balance_gl) AS total_gl,
    SUM(total_variance) AS total_variance,
    AVG(CASE WHEN variance_risk = 'High' THEN 1 ELSE 0 END) * 100 AS high_risk_pct
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360
GROUP BY segment1, segment2
ORDER BY total_variance DESC
LIMIT 20;

-- ============================================================================
-- SECTION 5: DATA QUALITY CHECKS
-- ============================================================================

-- 5.1 Check for NULL values in key columns
SELECT 
    'entity_360' AS table_name,
    SUM(CASE WHEN entity_id IS NULL THEN 1 ELSE 0 END) AS null_entity_id,
    SUM(CASE WHEN period_id IS NULL THEN 1 ELSE 0 END) AS null_period_id,
    SUM(CASE WHEN entity_name IS NULL THEN 1 ELSE 0 END) AS null_entity_name
FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360
UNION ALL
SELECT 
    'assignment_360',
    SUM(CASE WHEN assignment_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN period_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN entity_name IS NULL THEN 1 ELSE 0 END)
FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360;

-- 5.2 Date range coverage
SELECT 
    MIN(period_end_date) AS min_date,
    MAX(period_end_date) AS max_date,
    DATEDIFF('month', MIN(period_end_date), MAX(period_end_date)) AS months_covered,
    COUNT(DISTINCT period_end_date) AS distinct_periods
FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360;

-- 5.3 Enum value distributions
SELECT 'variance_risk_level' AS column_name, variance_risk_level AS value, COUNT(*) AS cnt
FROM COCO_LIVE_DB.DBT_MARTS.ENTITY_360 GROUP BY variance_risk_level
UNION ALL
SELECT 'status', status, COUNT(*) FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360 GROUP BY status
UNION ALL
SELECT 'reconciliation_status', reconciliation_status, COUNT(*) FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360 GROUP BY reconciliation_status
UNION ALL
SELECT 'variance_risk', variance_risk, COUNT(*) FROM COCO_LIVE_DB.DBT_MARTS.ASSIGNMENT_360 GROUP BY variance_risk;
