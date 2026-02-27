WITH reconciliation_summary AS (
    SELECT
        assignment_id,
        period_id,
        COUNT(*) AS reconciliation_count,
        COUNT(CASE WHEN reconciliation_type = 'Proof' THEN 1 END) AS proof_reconciliation_count,
        SUM(balance_bank) AS total_balance_bank,
        SUM(balance_calculated) AS total_balance_calculated,
        SUM(balance_subledger) AS total_balance_subledger,
        SUM(ABS(COALESCE(balance_bank, 0) - COALESCE(balance_calculated, 0))) AS total_bank_calc_diff,
        AVG(balance_bank) AS avg_balance_bank,
        MAX(balance_bank) AS max_balance_bank,
        MIN(balance_bank) AS min_balance_bank
    FROM COCO_LIVE_DB.DBT_MARTS.stg_rec_reconciliations
    GROUP BY assignment_id, period_id
)

SELECT * FROM reconciliation_summary