with variance as (
    select * from DBAPI_REPLICA_DB.PUBLIC.stg_var_activity
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
    v.var_activity_id,
    v.assignment_id,
    v.period_id,
    v.prior_period_id,
    a.entity_id,
    e.entity_code,
    e.entity_name,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_num,
    a.assignment_key,
    a.account_combination,
    a.currency,
    v.balance_gl_diff,
    v.balance_gl_base_diff,
    v.balance_gl_func_diff,
    v.balance_bank_diff,
    v.balance_bank_base_diff,
    v.balance_subledger_diff,
    v.balance_subledger_base_diff,
    v.variance,
    v.variance_base,
    v.variance_func,
    abs(v.variance) as variance_absolute,
    case
        when v.variance > 0 then 'Over'
        when v.variance < 0 then 'Under'
        else 'None'
    end as variance_direction,
    v.created_at,
    v.updated_at
from variance v
left join assignments a on v.assignment_id = a.assignment_id
left join entities e on a.entity_id = e.entity_id
left join periods p on v.period_id = p.period_id