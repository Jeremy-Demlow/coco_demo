

with recon_details as (
    select * from DBAPI_REPLICA_DB.PUBLIC.int_reconciliation_details
),

variance_analysis as (
    select * from DBAPI_REPLICA_DB.PUBLIC.int_variance_analysis
),

entity_period_summary as (
    select
        entity_id,
        entity_code,
        entity_name,
        period_id,
        period_year,
        period_quarter,
        period_month_num,
        period_end_date,
        count(distinct assignment_id) as total_assignments,
        sum(case when is_active then 1 else 0 end) as active_assignments,
        sum(case when has_activity then 1 else 0 end) as assignments_with_activity,
        sum(case when is_key_account then 1 else 0 end) as key_account_count,
        sum(balance_gl) as total_gl_balance,
        sum(balance_gl_base) as total_gl_balance_base,
        sum(balance_bank) as total_bank_balance,
        sum(balance_bank_base) as total_bank_balance_base,
        sum(balance_subledger) as total_subledger_balance,
        sum(balance_subledger_base) as total_subledger_balance_base,
        avg(balance_gl) as avg_gl_balance,
        max(last_update_date) as last_reconciliation_date
    from recon_details
    group by 1,2,3,4,5,6,7,8
),

entity_variance_summary as (
    select
        entity_id,
        period_id,
        count(*) as variance_count,
        sum(variance) as total_variance,
        sum(variance_base) as total_variance_base,
        avg(variance) as avg_variance,
        sum(variance_absolute) as total_absolute_variance,
        sum(case when variance_direction = 'Over' then 1 else 0 end) as over_variance_count,
        sum(case when variance_direction = 'Under' then 1 else 0 end) as under_variance_count,
        max(variance_absolute) as max_single_variance
    from variance_analysis
    group by 1,2
)

select
    eps.entity_id,
    eps.entity_code,
    eps.entity_name,
    eps.period_id,
    eps.period_year,
    eps.period_quarter,
    eps.period_month_num,
    eps.period_end_date,
    eps.total_assignments,
    eps.active_assignments,
    eps.assignments_with_activity,
    eps.key_account_count,
    round(eps.active_assignments * 100.0 / nullif(eps.total_assignments, 0), 2) as active_assignment_pct,
    round(eps.assignments_with_activity * 100.0 / nullif(eps.total_assignments, 0), 2) as activity_coverage_pct,
    eps.total_gl_balance,
    eps.total_gl_balance_base,
    eps.total_bank_balance,
    eps.total_bank_balance_base,
    eps.total_subledger_balance,
    eps.total_subledger_balance_base,
    eps.avg_gl_balance,
    eps.last_reconciliation_date,
    coalesce(evs.variance_count, 0) as variance_count,
    coalesce(evs.total_variance, 0) as total_variance,
    coalesce(evs.total_variance_base, 0) as total_variance_base,
    coalesce(evs.avg_variance, 0) as avg_variance,
    coalesce(evs.total_absolute_variance, 0) as total_absolute_variance,
    coalesce(evs.over_variance_count, 0) as over_variance_count,
    coalesce(evs.under_variance_count, 0) as under_variance_count,
    coalesce(evs.max_single_variance, 0) as max_single_variance,
    case 
        when evs.total_absolute_variance > 100000 then 'High Risk'
        when evs.total_absolute_variance > 10000 then 'Medium Risk'
        when evs.total_absolute_variance > 0 then 'Low Risk'
        else 'No Variance'
    end as variance_risk_level,
    current_timestamp() as dbt_updated_at
from entity_period_summary eps
left join entity_variance_summary evs 
    on eps.entity_id = evs.entity_id 
    and eps.period_id = evs.period_id