
  create or replace   view COCO_LIVE_DB.DBT_MARTS.stg_var_activity
  
   as (
    SELECT
    assignment_id,
    period_id,
    prior_period_id,
    var_activity_id,
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
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM COCO_LIVE_DB.CUSTOMER_A_DATA.var_activity
  );

