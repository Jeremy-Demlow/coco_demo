

WITH period_info AS (
    SELECT * FROM COCO_LIVE_DB.DBT_INTERMEDIATE.int_period_info_enriched
),

recon_agg AS (
    SELECT * FROM COCO_LIVE_DB.DBT_INTERMEDIATE.int_reconciliation_aggregates
),

variance_agg AS (
    SELECT * FROM COCO_LIVE_DB.DBT_INTERMEDIATE.int_variance_aggregates
),

dim_assignment AS (
    SELECT assignment_key, assignment_id FROM COCO_LIVE_DB.DBT.dim_assignment
),

dim_period AS (
    SELECT period_key, period_id FROM COCO_LIVE_DB.DBT.dim_period
),

fact_reconciliation AS (
    SELECT
        md5(cast(coalesce(cast(pi.assignment_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pi.period_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS reconciliation_fact_key,
        
        da.assignment_key,
        dp.period_key,
        
        pi.assignment_id,
        pi.period_id,
        pi.period_info_id,
        pi.consolidation_id,
        
        pi.is_active,
        pi.has_activity,
        pi.is_key_account,
        pi.purpose,
        pi.reconciliation_procedure,
        pi.recon_frequency,
        
        pi.balance_gl,
        pi.balance_gl_base,
        pi.balance_bank,
        pi.balance_bank_base,
        pi.balance_subledger,
        pi.balance_subledger_base,
        pi.balance_estimate,
        pi.balance_estimate_base,
        pi.balance_forecast,
        pi.balance_forecast_base,
        
        pi.gl_bank_difference,
        pi.gl_subledger_difference,
        pi.gl_estimate_difference,
        pi.gl_bank_variance_pct,
        
        COALESCE(ra.reconciliation_count, 0) AS reconciliation_count,
        COALESCE(ra.total_unidentified_amount, 0) AS total_unidentified_amount,
        ra.last_reconciliation_date,
        
        COALESCE(va.total_abs_variance, 0) AS total_abs_variance,
        va.avg_variance,
        va.max_variance,
        va.min_variance,
        COALESCE(va.variance_record_count, 0) AS variance_record_count,
        
        CASE 
            WHEN pi.is_active AND COALESCE(va.total_abs_variance, 0) = 0 THEN 'Fully Reconciled'
            WHEN pi.is_active AND COALESCE(va.total_abs_variance, 0) < 1000 THEN 'Minor Variance'
            WHEN pi.is_active AND COALESCE(va.total_abs_variance, 0) < 10000 THEN 'Moderate Variance'
            WHEN pi.is_active THEN 'High Variance'
            ELSE 'Inactive'
        END AS reconciliation_status,
        
        CASE 
            WHEN NOT pi.is_active THEN 0
            WHEN COALESCE(va.total_abs_variance, 0) = 0 THEN 100
            WHEN COALESCE(va.total_abs_variance, 0) < 1000 THEN 75
            WHEN COALESCE(va.total_abs_variance, 0) < 10000 THEN 50
            ELSE 25
        END AS reconciliation_health_score,
        
        pi.period_end_date,
        pi.period_year,
        pi.period_quarter,
        
        pi.account_balance_last_update_date,
        pi.last_update_date,
        pi.updated_at AS record_updated_at,
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM period_info pi
    INNER JOIN dim_assignment da ON pi.assignment_id = da.assignment_id
    INNER JOIN dim_period dp ON pi.period_id = dp.period_id
    LEFT JOIN recon_agg ra ON pi.assignment_id = ra.assignment_id AND pi.period_id = ra.period_id
    LEFT JOIN variance_agg va ON pi.assignment_id = va.assignment_id AND pi.period_id = va.period_id
)

SELECT * FROM fact_reconciliation