WITH assignment_variance_summary AS (
    SELECT
        assignment_id,
        period_id,
        COUNT(*) AS variance_record_count,
        SUM(ABS(variance)) AS total_absolute_variance,
        SUM(ABS(variance_base)) AS total_absolute_variance_base,
        SUM(ABS(variance_func)) AS total_absolute_variance_func,
        AVG(variance) AS avg_variance,
        MAX(ABS(variance)) AS max_variance,
        SUM(ABS(balance_gl_diff)) AS total_gl_variance,
        SUM(ABS(balance_bank_diff)) AS total_bank_variance
    FROM COCO_LIVE_DB.DBT_MARTS.stg_var_activity
    GROUP BY assignment_id, period_id
)

SELECT * FROM assignment_variance_summary