

WITH fct AS (
    SELECT * FROM COCO_LIVE_DB.DBT.fct_reconciliation
),

dim_assignment AS (
    SELECT * FROM COCO_LIVE_DB.DBT.dim_assignment
),

dim_period AS (
    SELECT * FROM COCO_LIVE_DB.DBT.dim_period
)

SELECT
    f.period_id,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_name,
    p.year_quarter_label,
    p.is_year_end,
    p.is_quarter_end,
    
    COUNT(DISTINCT f.assignment_id) AS total_assignments,
    COUNT(DISTINCT a.entity_id) AS entities_with_activity,
    
    SUM(CASE WHEN f.is_active THEN 1 ELSE 0 END) AS active_assignments,
    SUM(CASE WHEN f.is_key_account THEN 1 ELSE 0 END) AS key_accounts,
    SUM(CASE WHEN f.has_activity THEN 1 ELSE 0 END) AS assignments_with_activity,
    
    SUM(COALESCE(f.balance_gl, 0)) AS total_gl_balance,
    SUM(COALESCE(f.balance_bank, 0)) AS total_bank_balance,
    SUM(COALESCE(f.balance_estimate, 0)) AS total_estimate_balance,
    SUM(COALESCE(f.balance_forecast, 0)) AS total_forecast_balance,
    
    SUM(f.gl_bank_difference) AS total_gl_bank_difference,
    SUM(f.gl_subledger_difference) AS total_gl_subledger_difference,
    
    SUM(f.total_abs_variance) AS total_variance,
    AVG(NULLIF(f.total_abs_variance, 0)) AS avg_variance,
    MAX(f.max_variance) AS max_variance,
    
    SUM(f.reconciliation_count) AS total_reconciliation_items,
    SUM(f.total_unidentified_amount) AS total_unidentified,
    
    SUM(CASE WHEN f.reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) AS fully_reconciled,
    SUM(CASE WHEN f.reconciliation_status = 'Minor Variance' THEN 1 ELSE 0 END) AS minor_variance,
    SUM(CASE WHEN f.reconciliation_status = 'Moderate Variance' THEN 1 ELSE 0 END) AS moderate_variance,
    SUM(CASE WHEN f.reconciliation_status = 'High Variance' THEN 1 ELSE 0 END) AS high_variance,
    SUM(CASE WHEN f.reconciliation_status = 'Inactive' THEN 1 ELSE 0 END) AS inactive,
    
    ROUND(100.0 * SUM(CASE WHEN f.reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN f.is_active THEN 1 ELSE 0 END), 0), 2) AS completion_rate_pct,
    
    ROUND(100.0 * SUM(CASE WHEN f.reconciliation_status IN ('High Variance', 'Moderate Variance') THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN f.is_active THEN 1 ELSE 0 END), 0), 2) AS variance_alert_rate_pct,
    
    AVG(f.reconciliation_health_score) AS avg_health_score

FROM fct f
INNER JOIN dim_assignment a ON f.assignment_key = a.assignment_key
INNER JOIN dim_period p ON f.period_key = p.period_key
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
ORDER BY p.period_end_date DESC