
  create or replace   view COCO_LIVE_DB.DBT_MARTS.stg_rec_period_information
  
   as (
    SELECT
    pkid AS period_info_id,
    assignment_id,
    period_id,
    financial_statement_id,
    active_status AS is_active,
    activity_in_period,
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
    key_account AS is_key_account,
    rate_type,
    is_elimination_account,
    delete_flag AS is_deleted,
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM COCO_LIVE_DB.CUSTOMER_A_DATA.rec_period_information
WHERE delete_flag = 0
  );

