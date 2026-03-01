with source as (
    select * from COCO_LIVE_DB.CUSTOMER_A_DATA.var_activity
)

select
    var_activity_id,
    assignment_id,
    period_id,
    prior_period_id,
    balance_gl_diff,
    balance_gl_base_diff,
    balance_gl_func_diff,
    balance_estimate_diff,
    balance_estimate_base_diff,
    balance_estimate_func_diff,
    balance_subledger_diff,
    balance_subledger_base_diff,
    balance_subledger_func_diff,
    balance_bank_diff,
    balance_bank_base_diff,
    balance_bank_func_diff,
    balance_forecast_diff,
    balance_forecast_base_diff,
    balance_forecast_func_diff,
    variance,
    variance_base,
    variance_func,
    db_insert_date,
    db_update_date
from source