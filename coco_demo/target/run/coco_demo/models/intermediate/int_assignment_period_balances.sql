
  create or replace   view COCO_LIVE_DB.PUBLIC.int_assignment_period_balances
  
   as (
    with assignments as (
    select * from COCO_LIVE_DB.PUBLIC.stg_rec_assignments
),

period_info as (
    select * from COCO_LIVE_DB.PUBLIC.stg_rec_period_information
),

periods as (
    select * from COCO_LIVE_DB.PUBLIC.stg_rec_periods
)

select
    a.assignment_id,
    a.entity_id,
    a.assignment_type,
    a.combo_name,
    a.currency,
    a.segment1,
    a.segment2,
    a.segment3,
    p.period_id,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_num,
    pi.active_status,
    pi.key_account,
    coalesce(pi.balance_gl, 0) as balance_gl,
    coalesce(pi.balance_gl_base, 0) as balance_gl_base,
    coalesce(pi.balance_bank, 0) as balance_bank,
    coalesce(pi.balance_bank_base, 0) as balance_bank_base,
    coalesce(pi.balance_subledger, 0) as balance_subledger,
    coalesce(pi.balance_estimate, 0) as balance_estimate,
    coalesce(pi.balance_forecast, 0) as balance_forecast,
    abs(coalesce(pi.balance_gl, 0) - coalesce(pi.balance_bank, 0)) as gl_bank_variance,
    case 
        when pi.balance_gl is null then 'Missing GL Balance'
        when pi.balance_bank is null then 'Missing Bank Balance'
        when abs(coalesce(pi.balance_gl, 0) - coalesce(pi.balance_bank, 0)) > 1000 then 'High Variance'
        when abs(coalesce(pi.balance_gl, 0) - coalesce(pi.balance_bank, 0)) > 0 then 'Low Variance'
        else 'Reconciled'
    end as reconciliation_status,
    pi.db_update_date as last_updated_at
from assignments a
inner join period_info pi on a.assignment_id = pi.assignment_id
inner join periods p on pi.period_id = p.period_id
  );

