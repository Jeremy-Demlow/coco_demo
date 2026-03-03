
  create or replace   view COCO_LIVE_DB.DBT.entity_reconciliation_summary
  
   as (
    WITH base AS (
    SELECT * FROM COCO_LIVE_DB.DBT.reconciliation_360
)

SELECT
    entity_id,
    entity_code,
    entity_name,
    entity_type,
    parent_entity_name,
    hierarchy_depth,
    financial_review_required,
    period_id,
    period_end_date,
    period_year,
    period_quarter,
    period_month_name,
    
    COUNT(DISTINCT assignment_id) AS total_assignments,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_assignments,
    SUM(CASE WHEN is_key_account THEN 1 ELSE 0 END) AS key_accounts,
    
    SUM(COALESCE(balance_gl, 0)) AS total_gl_balance,
    SUM(COALESCE(balance_bank, 0)) AS total_bank_balance,
    SUM(COALESCE(balance_subledger, 0)) AS total_subledger_balance,
    
    SUM(gl_bank_difference) AS total_gl_bank_difference,
    SUM(gl_subledger_difference) AS total_gl_subledger_difference,
    
    SUM(total_abs_variance) AS total_variance,
    AVG(NULLIF(total_abs_variance, 0)) AS avg_variance_per_assignment,
    MAX(max_variance) AS peak_variance,
    
    SUM(reconciliation_count) AS total_reconciliations,
    SUM(total_unidentified_amount) AS total_unidentified,
    
    SUM(CASE WHEN reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) AS fully_reconciled_count,
    SUM(CASE WHEN reconciliation_status = 'High Variance' THEN 1 ELSE 0 END) AS high_variance_count,
    
    ROUND(100.0 * SUM(CASE WHEN reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS reconciliation_completion_rate,
    
    MAX(last_update_date) AS latest_activity_date

FROM base
WHERE entity_id IS NOT NULL
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
  );

