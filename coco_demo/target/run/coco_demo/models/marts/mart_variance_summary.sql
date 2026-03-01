
  create or replace   view COCO_LIVE_DB.PUBLIC.mart_variance_summary
  
   as (
    with assignment_balances as (
    select * from COCO_LIVE_DB.PUBLIC.int_assignment_period_balances
),

entities as (
    select * from COCO_LIVE_DB.PUBLIC.stg_org_entities
),

variance_analysis as (
    select * from COCO_LIVE_DB.PUBLIC.int_variance_analysis
),

period_variance as (
    select
        va.period_id,
        va.period_end_date,
        va.period_year,
        va.period_quarter,
        ab.entity_id,
        count(distinct va.assignment_id) as assignments_with_variance,
        sum(va.abs_variance) as total_variance,
        avg(va.abs_variance) as avg_variance,
        count(case when va.variance_severity = 'Critical' then 1 end) as critical_count,
        count(case when va.variance_severity = 'High' then 1 end) as high_count,
        count(case when va.variance_severity = 'Medium' then 1 end) as medium_count,
        count(case when va.variance_severity = 'Low' then 1 end) as low_count
    from variance_analysis va
    inner join assignment_balances ab on va.assignment_id = ab.assignment_id and va.period_id = ab.period_id
    group by va.period_id, va.period_end_date, va.period_year, va.period_quarter, ab.entity_id
)

select
    pv.period_id,
    pv.period_end_date,
    pv.period_year,
    pv.period_quarter,
    pv.entity_id,
    e.entity_code,
    e.entity_name,
    pv.assignments_with_variance,
    pv.total_variance,
    pv.avg_variance,
    pv.critical_count,
    pv.high_count,
    pv.medium_count,
    pv.low_count,
    pv.critical_count + pv.high_count as severe_variance_count,
    case
        when pv.critical_count > 0 then 'Critical'
        when pv.high_count > 2 then 'High Risk'
        when pv.medium_count > 5 then 'Medium Risk'
        else 'Low Risk'
    end as period_risk_level,
    current_timestamp() as dbt_updated_at
from period_variance pv
inner join entities e on pv.entity_id = e.entity_id
  );

