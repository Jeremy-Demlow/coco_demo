

WITH variance_aggregates AS (
    SELECT
        assignment_id,
        period_id,
        prior_period_id,
        
        SUM(COALESCE(gl_variance, 0)) AS total_gl_variance,
        SUM(COALESCE(bank_variance, 0)) AS total_bank_variance,
        SUM(COALESCE(subledger_variance, 0)) AS total_subledger_variance,
        SUM(COALESCE(estimate_variance, 0)) AS total_estimate_variance,
        
        SUM(ABS(COALESCE(total_variance, 0))) AS total_abs_variance,
        AVG(total_variance) AS avg_variance,
        MAX(ABS(total_variance)) AS max_variance,
        MIN(total_variance) AS min_variance,
        
        COUNT(*) AS variance_record_count,
        MAX(updated_at) AS last_variance_date
        
    FROM COCO_LIVE_DB.DBT_STAGING.stg_var_activity
    GROUP BY 1, 2, 3
)

SELECT * FROM variance_aggregates