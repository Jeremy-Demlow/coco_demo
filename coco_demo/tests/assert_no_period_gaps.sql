WITH period_gaps AS (
    SELECT
        period_end_date,
        LAG(period_end_date) OVER (ORDER BY period_end_date) AS prev_period,
        DATEDIFF('day', LAG(period_end_date) OVER (ORDER BY period_end_date), period_end_date) AS days_gap
    FROM {{ ref('stg_rec_periods') }}
)

SELECT *
FROM period_gaps
WHERE days_gap > 35
  AND prev_period IS NOT NULL
