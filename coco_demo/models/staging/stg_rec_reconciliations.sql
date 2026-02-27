select
    pkid as reconciliation_id,
    account_assignment_id as assignment_id,
    period_id,
    activity_period_id,
    variance_activity_period_id,
    variance_period_id,
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
    delete_flag as is_deleted,
    db_insert_date as created_at,
    db_update_date as updated_at
from {{ source('replica', 'rec_reconciliations') }}
where delete_flag = false or delete_flag is null
