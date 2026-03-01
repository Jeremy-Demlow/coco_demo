
  create or replace   view COCO_LIVE_DB.PUBLIC.mart_entity_360
  
   as (
    with entities as (
    select * from COCO_LIVE_DB.PUBLIC.stg_org_entities
),

assignment_balances as (
    select * from COCO_LIVE_DB.PUBLIC.int_assignment_period_balances
),

variance_analysis as (
    select * from COCO_LIVE_DB.PUBLIC.int_variance_analysis
),

entity_assignment_summary as (
    select
        entity_id,
        count(distinct assignment_id) as total_assignments,
        count(distinct period_id) as periods_with_activity,
        sum(balance_gl) as total_gl_balance,
        sum(balance_bank) as total_bank_balance,
        sum(balance_subledger) as total_subledger_balance,
        sum(gl_bank_variance) as total_gl_bank_variance,
        count(case when reconciliation_status = 'Reconciled' then 1 end) as reconciled_count,
        count(case when reconciliation_status = 'High Variance' then 1 end) as high_variance_count,
        count(case when reconciliation_status = 'Low Variance' then 1 end) as low_variance_count,
        count(case when reconciliation_status like 'Missing%' then 1 end) as missing_data_count,
        max(last_updated_at) as last_activity_date
    from assignment_balances
    group by entity_id
),

entity_variance_summary as (
    select
        ab.entity_id,
        count(distinct va.var_activity_id) as total_variance_records,
        sum(va.abs_variance) as total_variance_amount,
        avg(va.abs_variance) as avg_variance_amount,
        count(case when va.variance_severity = 'Critical' then 1 end) as critical_variance_count,
        count(case when va.variance_severity = 'High' then 1 end) as high_severity_count,
        count(case when va.variance_severity = 'Medium' then 1 end) as medium_severity_count,
        count(case when va.variance_direction = 'Positive' then 1 end) as positive_variance_count,
        count(case when va.variance_direction = 'Negative' then 1 end) as negative_variance_count
    from assignment_balances ab
    inner join variance_analysis va on ab.assignment_id = va.assignment_id
    group by ab.entity_id
),

latest_period_status as (
    select
        entity_id,
        period_id,
        sum(balance_gl) as current_period_gl_balance,
        sum(balance_bank) as current_period_bank_balance,
        sum(gl_bank_variance) as current_period_variance,
        count(case when reconciliation_status = 'Reconciled' then 1 end) as current_reconciled_count,
        count(case when reconciliation_status != 'Reconciled' then 1 end) as current_unreconciled_count
    from assignment_balances
    where period_id = (select max(period_id) from assignment_balances)
    group by entity_id, period_id
)

select
    e.entity_id,
    e.entity_code,
    e.entity_name,
    e.entity_description,
    e.entity_type,
    e.parent_id,
    e.parent_name,
    e.ownership,
    e.depth as hierarchy_depth,
    e.lineage as hierarchy_lineage,
    e.has_children,
    e.financial_review_required,
    
    coalesce(eas.total_assignments, 0) as total_assignments,
    coalesce(eas.periods_with_activity, 0) as periods_with_activity,
    coalesce(eas.total_gl_balance, 0) as total_gl_balance,
    coalesce(eas.total_bank_balance, 0) as total_bank_balance,
    coalesce(eas.total_subledger_balance, 0) as total_subledger_balance,
    coalesce(eas.total_gl_bank_variance, 0) as total_gl_bank_variance,
    coalesce(eas.reconciled_count, 0) as reconciled_count,
    coalesce(eas.high_variance_count, 0) as high_variance_count,
    coalesce(eas.low_variance_count, 0) as low_variance_count,
    coalesce(eas.missing_data_count, 0) as missing_data_count,
    eas.last_activity_date,
    
    case 
        when coalesce(eas.total_assignments, 0) = 0 then 0
        else round(100.0 * coalesce(eas.reconciled_count, 0) / eas.total_assignments, 2)
    end as reconciliation_completion_pct,
    
    coalesce(evs.total_variance_records, 0) as total_variance_records,
    coalesce(evs.total_variance_amount, 0) as total_variance_amount,
    coalesce(evs.avg_variance_amount, 0) as avg_variance_amount,
    coalesce(evs.critical_variance_count, 0) as critical_variance_count,
    coalesce(evs.high_severity_count, 0) as high_severity_count,
    coalesce(evs.positive_variance_count, 0) as positive_variance_count,
    coalesce(evs.negative_variance_count, 0) as negative_variance_count,
    
    coalesce(lps.current_period_gl_balance, 0) as current_period_gl_balance,
    coalesce(lps.current_period_bank_balance, 0) as current_period_bank_balance,
    coalesce(lps.current_period_variance, 0) as current_period_variance,
    coalesce(lps.current_reconciled_count, 0) as current_reconciled_count,
    coalesce(lps.current_unreconciled_count, 0) as current_unreconciled_count,
    
    case
        when coalesce(evs.critical_variance_count, 0) > 0 then 'Critical'
        when coalesce(eas.high_variance_count, 0) > 5 then 'At Risk'
        when coalesce(eas.reconciled_count, 0) = coalesce(eas.total_assignments, 0) 
             and coalesce(eas.total_assignments, 0) > 0 then 'Healthy'
        when coalesce(eas.total_assignments, 0) = 0 then 'No Activity'
        else 'Needs Attention'
    end as entity_health_status,
    
    current_timestamp() as dbt_updated_at

from entities e
left join entity_assignment_summary eas on e.entity_id = eas.entity_id
left join entity_variance_summary evs on e.entity_id = evs.entity_id
left join latest_period_status lps on e.entity_id = lps.entity_id
  );

