WITH validation AS (
    SELECT
        period_end_date,
        total_variance,
        total_gl_balance,
        completion_rate_pct,
        CASE 
            WHEN completion_rate_pct < 0 THEN 'Negative completion rate'
            WHEN completion_rate_pct > 100 THEN 'Completion rate > 100%'
            WHEN total_variance < 0 THEN 'Negative variance'
            ELSE NULL
        END AS issue
    FROM COCO_LIVE_DB.DBT.period_reconciliation_summary
)

SELECT *
FROM validation
WHERE issue IS NOT NULL