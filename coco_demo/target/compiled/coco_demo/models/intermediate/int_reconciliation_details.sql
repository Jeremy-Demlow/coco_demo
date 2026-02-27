with period_info as (
    select * from DBAPI_REPLICA_DB.PUBLIC.stg_rec_period_information
),

assignments as (
    select * from DBAPI_REPLICA_DB.PUBLIC.stg_rec_assignments
),

entities as (
    select * from DBAPI_REPLICA_DB.PUBLIC.stg_org_entities
),

periods as (
    select * from DBAPI_REPLICA_DB.PUBLIC.stg_rec_periods
)

select
    pi.period_info_id,
    pi.assignment_id,
    pi.period_id,
    a.entity_id,
    e.entity_code,
    e.entity_name,
    e.parent_id as entity_parent_id,
    e.parent_name as entity_parent_name,
    e.hierarchy_depth,
    e.entity_type,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_num,
    a.assignment_key,
    a.assignment_type,
    a.account_combination,
    a.assignment_description,
    a.currency,
    a.segment1, a.segment2, a.segment3, a.segment4, a.segment5,
    pi.is_active,
    pi.has_activity,
    pi.is_key_account,
    pi.balance_gl,
    pi.balance_gl_base,
    pi.balance_gl_func,
    pi.balance_bank,
    pi.balance_bank_base,
    pi.balance_bank_func,
    pi.balance_subledger,
    pi.balance_subledger_base,
    pi.balance_subledger_func,
    pi.balance_estimate,
    pi.balance_estimate_func,
    pi.balance_forecast,
    pi.balance_forecast_func,
    pi.purpose,
    pi.reconciliation_procedure,
    pi.recon_frequency,
    pi.last_update_date,
    pi.created_at,
    pi.updated_at
from period_info pi
left join assignments a on pi.assignment_id = a.assignment_id
left join entities e on a.entity_id = e.entity_id
left join periods p on pi.period_id = p.period_id