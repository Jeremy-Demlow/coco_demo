

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
    a.entity_id,
    a.entity_code,
    a.entity_name,
    a.entity_type,
    a.parent_entity_name,
    a.hierarchy_depth,
    a.financial_review_required,
    
    f.period_id,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_name,
    p.year_quarter_label,
    
    COUNT(DISTINCT f.assignment_id) AS total_assignments,
    SUM(CASE WHEN f.is_active THEN 1 ELSE 0 END) AS active_assignments,
    SUM(CASE WHEN f.is_key_account THEN 1 ELSE 0 END) AS key_accounts,
    
    SUM(COALESCE(f.balance_gl, 0)) AS total_gl_balance,
    SUM(COALESCE(f.balance_bank, 0)) AS total_bank_balance,
    SUM(COALESCE(f.balance_subledger, 0)) AS total_subledger_balance,
    
    SUM(f.gl_bank_difference) AS total_gl_bank_difference,
    SUM(f.gl_subledger_difference) AS total_gl_subledger_difference,
    
    SUM(f.total_abs_variance) AS total_variance,
    AVG(NULLIF(f.total_abs_variance, 0)) AS avg_variance_per_assignment,
    MAX(f.max_variance) AS peak_variance,
    
    SUM(f.reconciliation_count) AS total_reconciliations,
    SUM(f.total_unidentified_amount) AS total_unidentified,
    
    SUM(CASE WHEN f.reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) AS fully_reconciled_count,
    SUM(CASE WHEN f.reconciliation_status = 'High Variance' THEN 1 ELSE 0 END) AS high_variance_count,
    SUM(CASE WHEN f.reconciliation_status = 'Moderate Variance' THEN 1 ELSE 0 END) AS moderate_variance_count,
    SUM(CASE WHEN f.reconciliation_status = 'Minor Variance' THEN 1 ELSE 0 END) AS minor_variance_count,
    
    ROUND(100.0 * SUM(CASE WHEN f.reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN f.is_active THEN 1 ELSE 0 END), 0), 2) AS reconciliation_completion_rate,
    
    AVG(f.reconciliation_health_score) AS avg_health_score,
    
    MAX(f.last_update_date) AS latest_activity_date

FROM fct f
INNER JOIN dim_assignment a ON f.assignment_key = a.assignment_key
INNER JOIN dim_period p ON f.period_key = p.period_key
WHERE a.entity_id IS NOT NULL
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13