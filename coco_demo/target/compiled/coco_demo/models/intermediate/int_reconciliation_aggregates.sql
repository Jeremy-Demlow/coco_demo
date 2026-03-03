

WITH reconciliation_aggregates AS (
    SELECT
        assignment_id,
        period_id,
        COUNT(*) AS reconciliation_count,
        SUM(COALESCE(amount_unidentified, 0)) AS total_unidentified_amount,
        SUM(COALESCE(balance_calculated, 0)) AS total_calculated_balance,
        MAX(updated_at) AS last_reconciliation_date
    FROM COCO_LIVE_DB.DBT_STAGING.stg_rec_reconciliations
    GROUP BY 1, 2
)

SELECT * FROM reconciliation_aggregates