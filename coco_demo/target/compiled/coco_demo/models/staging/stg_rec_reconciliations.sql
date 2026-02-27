SELECT
    pkid AS reconciliation_id,
    account_assignment_id AS assignment_id,
    period_id,
    reconciliation_type,
    balance_bank,
    balance_bank_base,
    balance_bank_func,
    balance_calculated,
    balance_calculated_base,
    balance_calculated_func,
    balance_subledger,
    balance_subledger_base,
    balance_subledger_func,
    amount_unidentified,
    delete_flag AS is_deleted,
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM COCO_LIVE_DB.CUSTOMER_A_DATA.rec_reconciliations
WHERE delete_flag = 0