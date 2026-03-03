
  create or replace   view COCO_LIVE_DB.DBT.period_reconciliation_summary
  
   as (
    WITH base AS (
    SELECT * FROM COCO_LIVE_DB.DBT.reconciliation_360
)

SELECT
    period_id,
    period_end_date,
    period_year,
    period_quarter,
    period_month_name,
    
    COUNT(DISTINCT assignment_id) AS total_assignments,
    COUNT(DISTINCT entity_id) AS entities_with_activity,
    
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_assignments,
    SUM(CASE WHEN is_key_account THEN 1 ELSE 0 END) AS key_accounts,
    SUM(CASE WHEN has_activity THEN 1 ELSE 0 END) AS assignments_with_activity,
    
    SUM(COALESCE(balance_gl, 0)) AS total_gl_balance,
    SUM(COALESCE(balance_bank, 0)) AS total_bank_balance,
    SUM(COALESCE(balance_estimate, 0)) AS total_estimate_balance,
    SUM(COALESCE(balance_forecast, 0)) AS total_forecast_balance,
    
    SUM(gl_bank_difference) AS total_gl_bank_difference,
    SUM(gl_subledger_difference) AS total_gl_subledger_difference,
    
    SUM(total_abs_variance) AS total_variance,
    AVG(NULLIF(total_abs_variance, 0)) AS avg_variance,
    MAX(max_variance) AS max_variance,
    
    SUM(reconciliation_count) AS total_reconciliation_items,
    SUM(total_unidentified_amount) AS total_unidentified,
    
    SUM(CASE WHEN reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) AS fully_reconciled,
    SUM(CASE WHEN reconciliation_status = 'Minor Variance' THEN 1 ELSE 0 END) AS minor_variance,
    SUM(CASE WHEN reconciliation_status = 'Moderate Variance' THEN 1 ELSE 0 END) AS moderate_variance,
    SUM(CASE WHEN reconciliation_status = 'High Variance' THEN 1 ELSE 0 END) AS high_variance,
    SUM(CASE WHEN reconciliation_status = 'Inactive' THEN 1 ELSE 0 END) AS inactive,
    
    ROUND(100.0 * SUM(CASE WHEN reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN is_active THEN 1 ELSE 0 END), 0), 2) AS completion_rate_pct,
    
    ROUND(100.0 * SUM(CASE WHEN reconciliation_status IN ('High Variance', 'Moderate Variance') THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN is_active THEN 1 ELSE 0 END), 0), 2) AS variance_alert_rate_pct

FROM base
GROUP BY 1, 2, 3, 4, 5
ORDER BY period_end_date DESC
  );

