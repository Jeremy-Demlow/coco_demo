
  create or replace   view COCO_LIVE_DB.PUBLIC.stg_rec_period_information
  
   as (
    with source as (
    select * from COCO_LIVE_DB.CUSTOMER_A_DATA.rec_period_information
)

select
    pkid as period_info_id,
    assignment_id,
    period_id,
    active_status,
    activity_in_period,
    key_account,
    balance_gl,
    balance_gl_base,
    balance_gl_func,
    balance_bank,
    balance_bank_base,
    balance_bank_func,
    balance_subledger,
    balance_subledger_base,
    balance_subledger_func,
    balance_estimate,
    balance_estimate_base,
    balance_estimate_func,
    balance_forecast,
    balance_forecast_base,
    balance_forecast_func,
    rate_type,
    is_elimination_account,
    delete_flag,
    db_insert_date,
    db_update_date
from source
where delete_flag = 0 or delete_flag is null
  );

