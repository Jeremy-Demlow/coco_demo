with source as (
    select * from {{ source('coco_live', 'rec_reconciliations') }}
)

select
    pkid as reconciliation_id,
    account_assignment_id as assignment_id,
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
    delete_flag,
    db_insert_date,
    db_update_date
from source
where delete_flag = 0 or delete_flag is null
