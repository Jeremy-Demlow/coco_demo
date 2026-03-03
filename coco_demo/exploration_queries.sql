-- ============================================================
-- RECONCILIATION 360 DATA MODEL - EXPLORATION QUERIES
-- ============================================================
-- Use these queries to understand the reconciliation data model
-- and explore the key metrics and dimensions available.
-- ============================================================

-- ============================================================
-- 1. DATA MODEL OVERVIEW
-- ============================================================

-- 1.1 Quick summary of data volume
SELECT 
    'reconciliation_360' AS model,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT assignment_id) AS unique_assignments,
    COUNT(DISTINCT entity_name) AS unique_entities,
    COUNT(DISTINCT period_end_date) AS unique_periods
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360;

-- 1.2 Date range covered
SELECT 
    MIN(period_end_date) AS earliest_period,
    MAX(period_end_date) AS latest_period,
    DATEDIFF('month', MIN(period_end_date), MAX(period_end_date)) AS months_of_data
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360;

-- 1.3 Sample of the main reconciliation_360 view
SELECT *
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
LIMIT 10;

-- ============================================================
-- 2. RECONCILIATION STATUS ANALYSIS
-- ============================================================

-- 2.1 Overall status distribution
SELECT 
    reconciliation_status,
    COUNT(*) AS assignment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
GROUP BY reconciliation_status
ORDER BY assignment_count DESC;

-- 2.2 Status distribution by period (most recent 6 months)
SELECT 
    period_end_date,
    period_month_name,
    reconciliation_status,
    COUNT(*) AS count
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE period_end_date >= DATEADD('month', -6, (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.RECONCILIATION_360))
GROUP BY period_end_date, period_month_name, reconciliation_status
ORDER BY period_end_date DESC, reconciliation_status;

-- 2.3 Completion rate trend over time
SELECT 
    period_end_date,
    period_year,
    period_month_name,
    COUNT(*) AS total_assignments,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_assignments,
    SUM(CASE WHEN reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) AS fully_reconciled,
    ROUND(100.0 * SUM(CASE WHEN reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN is_active THEN 1 ELSE 0 END), 0), 2) AS completion_rate_pct
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
GROUP BY period_end_date, period_year, period_month_name
ORDER BY period_end_date;

-- ============================================================
-- 3. ENTITY ANALYSIS
-- ============================================================

-- 3.1 Top 20 entities by assignment count
SELECT 
    entity_name,
    entity_code,
    COUNT(DISTINCT assignment_id) AS total_assignments,
    COUNT(DISTINCT period_id) AS periods_active
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
GROUP BY entity_name, entity_code
ORDER BY total_assignments DESC
LIMIT 20;

-- 3.2 Entity hierarchy depth distribution
SELECT 
    hierarchy_depth,
    COUNT(DISTINCT entity_name) AS entity_count,
    COUNT(DISTINCT assignment_id) AS assignment_count
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE hierarchy_depth IS NOT NULL
GROUP BY hierarchy_depth
ORDER BY hierarchy_depth;

-- 3.3 Entities with highest variance (latest period)
SELECT 
    entity_name,
    entity_code,
    COUNT(*) AS assignments,
    SUM(total_abs_variance) AS total_variance,
    AVG(total_abs_variance) AS avg_variance,
    SUM(CASE WHEN reconciliation_status = 'High Variance' THEN 1 ELSE 0 END) AS high_variance_count
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE period_end_date = (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.RECONCILIATION_360)
GROUP BY entity_name, entity_code
HAVING SUM(total_abs_variance) > 0
ORDER BY total_variance DESC
LIMIT 20;

-- ============================================================
-- 4. VARIANCE ANALYSIS
-- ============================================================

-- 4.1 Variance distribution summary
SELECT 
    CASE 
        WHEN total_abs_variance = 0 THEN 'Zero Variance'
        WHEN total_abs_variance < 100 THEN '< $100'
        WHEN total_abs_variance < 1000 THEN '$100 - $1K'
        WHEN total_abs_variance < 10000 THEN '$1K - $10K'
        WHEN total_abs_variance < 100000 THEN '$10K - $100K'
        ELSE '> $100K'
    END AS variance_bucket,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE is_active = TRUE
GROUP BY 1
ORDER BY 
    CASE variance_bucket
        WHEN 'Zero Variance' THEN 1
        WHEN '< $100' THEN 2
        WHEN '$100 - $1K' THEN 3
        WHEN '$1K - $10K' THEN 4
        WHEN '$10K - $100K' THEN 5
        ELSE 6
    END;

-- 4.2 Top 20 highest variance assignments (latest period)
SELECT 
    assignment_id,
    entity_name,
    account_combination,
    currency,
    reconciliation_status,
    balance_gl,
    balance_bank,
    gl_bank_difference,
    total_abs_variance
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE period_end_date = (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.RECONCILIATION_360)
  AND is_active = TRUE
ORDER BY total_abs_variance DESC
LIMIT 20;

-- 4.3 Variance trend over time
SELECT 
    period_end_date,
    period_year,
    period_quarter,
    SUM(total_abs_variance) AS total_variance,
    AVG(NULLIF(total_abs_variance, 0)) AS avg_variance,
    MAX(total_abs_variance) AS max_single_variance
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE is_active = TRUE
GROUP BY period_end_date, period_year, period_quarter
ORDER BY period_end_date;

-- ============================================================
-- 5. KEY ACCOUNTS FOCUS
-- ============================================================

-- 5.1 Key accounts overview
SELECT 
    COUNT(*) AS total_key_account_records,
    COUNT(DISTINCT assignment_id) AS unique_key_accounts,
    COUNT(DISTINCT entity_name) AS entities_with_key_accounts,
    SUM(CASE WHEN reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) AS fully_reconciled,
    SUM(CASE WHEN reconciliation_status = 'High Variance' THEN 1 ELSE 0 END) AS high_variance
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE is_key_account = TRUE;

-- 5.2 Key accounts requiring attention (latest period)
SELECT 
    entity_name,
    account_combination,
    reconciliation_status,
    balance_gl,
    balance_bank,
    total_abs_variance,
    last_update_date
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE is_key_account = TRUE
  AND period_end_date = (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.RECONCILIATION_360)
  AND reconciliation_status IN ('High Variance', 'Moderate Variance')
ORDER BY total_abs_variance DESC;

-- ============================================================
-- 6. CURRENCY ANALYSIS
-- ============================================================

-- 6.1 Assignment distribution by currency
SELECT 
    currency,
    COUNT(DISTINCT assignment_id) AS assignments,
    COUNT(*) AS total_records,
    SUM(COALESCE(balance_gl, 0)) AS total_gl_balance
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE currency IS NOT NULL
GROUP BY currency
ORDER BY assignments DESC;

-- ============================================================
-- 7. SUMMARY VIEWS EXPLORATION
-- ============================================================

-- 7.1 Period summary view (most recent 12 periods)
SELECT *
FROM COCO_LIVE_DB.DBT.PERIOD_RECONCILIATION_SUMMARY
ORDER BY period_end_date DESC
LIMIT 12;

-- 7.2 Entity summary view sample (latest period, top performers)
SELECT 
    entity_name,
    total_assignments,
    active_assignments,
    fully_reconciled_count,
    high_variance_count,
    reconciliation_completion_rate,
    total_variance
FROM COCO_LIVE_DB.DBT.ENTITY_RECONCILIATION_SUMMARY
WHERE period_end_date = (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.ENTITY_RECONCILIATION_SUMMARY)
ORDER BY reconciliation_completion_rate DESC
LIMIT 20;

-- 7.3 Entity summary - worst performers (latest period)
SELECT 
    entity_name,
    total_assignments,
    active_assignments,
    fully_reconciled_count,
    high_variance_count,
    reconciliation_completion_rate,
    total_variance
FROM COCO_LIVE_DB.DBT.ENTITY_RECONCILIATION_SUMMARY
WHERE period_end_date = (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.ENTITY_RECONCILIATION_SUMMARY)
  AND active_assignments > 0
ORDER BY reconciliation_completion_rate ASC
LIMIT 20;

-- ============================================================
-- 8. ACCOUNT SEGMENT ANALYSIS
-- ============================================================

-- 8.1 Distribution by segment1 (if populated)
SELECT 
    segment1,
    COUNT(DISTINCT assignment_id) AS assignments,
    SUM(COALESCE(balance_gl, 0)) AS total_gl_balance,
    SUM(total_abs_variance) AS total_variance
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE segment1 IS NOT NULL
  AND period_end_date = (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.RECONCILIATION_360)
GROUP BY segment1
ORDER BY assignments DESC
LIMIT 20;

-- ============================================================
-- 9. ACTIVITY & FRESHNESS
-- ============================================================

-- 9.1 Data freshness check
SELECT 
    MAX(last_update_date) AS most_recent_update,
    MIN(last_update_date) AS oldest_update,
    COUNT(DISTINCT DATE(last_update_date)) AS days_with_updates
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE last_update_date IS NOT NULL;

-- 9.2 Assignments by activity status (latest period)
SELECT 
    CASE 
        WHEN has_activity THEN 'Has Activity'
        ELSE 'No Activity'
    END AS activity_status,
    COUNT(*) AS count,
    SUM(COALESCE(balance_gl, 0)) AS total_gl_balance
FROM COCO_LIVE_DB.DBT.RECONCILIATION_360
WHERE period_end_date = (SELECT MAX(period_end_date) FROM COCO_LIVE_DB.DBT.RECONCILIATION_360)
GROUP BY 1;

-- ============================================================
-- 10. AVAILABLE COLUMNS REFERENCE
-- ============================================================

-- 10.1 List all columns in reconciliation_360
SELECT 
    column_name,
    data_type,
    is_nullable
FROM COCO_LIVE_DB.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'DBT'
  AND table_name = 'RECONCILIATION_360'
ORDER BY ordinal_position;
