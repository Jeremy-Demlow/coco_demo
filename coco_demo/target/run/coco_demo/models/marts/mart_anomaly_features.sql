
  create or replace   view COCO_LIVE_DB.PUBLIC.mart_anomaly_features
  
   as (
    with assignment_balances as (
    select * from COCO_LIVE_DB.PUBLIC.int_assignment_period_balances
),

variance_analysis as (
    select * from COCO_LIVE_DB.PUBLIC.int_variance_analysis
),

entities as (
    select * from COCO_LIVE_DB.PUBLIC.stg_org_entities
),

periods as (
    select * from COCO_LIVE_DB.PUBLIC.stg_rec_periods
),

assignment_stats as (
    select
        assignment_id,
        count(*) as total_periods,
        avg(balance_gl) as avg_gl_balance,
        stddev(balance_gl) as stddev_gl_balance,
        avg(balance_bank) as avg_bank_balance,
        stddev(balance_bank) as stddev_bank_balance,
        avg(gl_bank_variance) as avg_gl_bank_variance,
        stddev(gl_bank_variance) as stddev_gl_bank_variance,
        min(balance_gl) as min_gl_balance,
        max(balance_gl) as max_gl_balance,
        sum(case when reconciliation_status = 'High Variance' then 1 else 0 end) as high_variance_periods
    from assignment_balances
    group by assignment_id
),

variance_stats as (
    select
        assignment_id,
        count(*) as variance_records,
        avg(abs_variance) as avg_abs_variance,
        stddev(abs_variance) as stddev_abs_variance,
        max(abs_variance) as max_abs_variance,
        sum(case when variance_severity = 'Critical' then 1 else 0 end) as critical_count,
        sum(case when variance_severity = 'High' then 1 else 0 end) as high_count,
        sum(case when variance_direction = 'Positive' then 1 else 0 end) as positive_variance_count,
        sum(case when variance_direction = 'Negative' then 1 else 0 end) as negative_variance_count
    from variance_analysis
    group by assignment_id
),

period_features as (
    select
        ab.assignment_id,
        ab.entity_id,
        ab.period_id,
        p.period_end_date,
        p.period_year,
        p.period_quarter,
        p.period_month_num,
        ab.assignment_type,
        ab.balance_gl,
        ab.balance_bank,
        ab.balance_subledger,
        ab.gl_bank_variance,
        ab.reconciliation_status,
        
        va.variance as period_variance,
        va.abs_variance as period_abs_variance,
        va.variance_severity,
        va.variance_direction,
        va.balance_gl_diff,
        va.balance_bank_diff,
        
        ast.avg_gl_balance as hist_avg_gl_balance,
        ast.stddev_gl_balance as hist_stddev_gl_balance,
        ast.avg_bank_balance as hist_avg_bank_balance,
        ast.avg_gl_bank_variance as hist_avg_variance,
        ast.stddev_gl_bank_variance as hist_stddev_variance,
        ast.high_variance_periods as hist_high_variance_count,
        
        vs.avg_abs_variance as hist_avg_abs_variance,
        vs.stddev_abs_variance as hist_stddev_abs_variance,
        vs.max_abs_variance as hist_max_abs_variance,
        vs.critical_count as hist_critical_count,
        vs.high_count as hist_high_count,
        
        case 
            when ast.stddev_gl_balance > 0 
            then (ab.balance_gl - ast.avg_gl_balance) / ast.stddev_gl_balance 
            else 0 
        end as gl_balance_zscore,
        
        case 
            when ast.stddev_gl_bank_variance > 0 
            then (ab.gl_bank_variance - ast.avg_gl_bank_variance) / ast.stddev_gl_bank_variance 
            else 0 
        end as variance_zscore,
        
        case 
            when vs.stddev_abs_variance > 0 
            then (va.abs_variance - vs.avg_abs_variance) / vs.stddev_abs_variance 
            else 0 
        end as abs_variance_zscore,
        
        coalesce(ab.balance_gl, 0) - coalesce(ab.balance_bank, 0) as gl_bank_diff,
        
        case when abs(coalesce(ab.balance_gl, 0)) > 0 
            then abs(ab.gl_bank_variance) / abs(ab.balance_gl) 
            else 0 
        end as variance_to_gl_ratio,
        
        lag(ab.balance_gl, 1) over (partition by ab.assignment_id order by ab.period_id) as prev_period_gl,
        lag(ab.gl_bank_variance, 1) over (partition by ab.assignment_id order by ab.period_id) as prev_period_variance,
        
        coalesce(ab.balance_gl, 0) - coalesce(lag(ab.balance_gl, 1) over (partition by ab.assignment_id order by ab.period_id), ab.balance_gl) as gl_period_change,
        
        e.entity_type,
        e.ownership,
        e.depth as hierarchy_depth,
        
        case 
            when va.variance_severity in ('Critical', 'High') then 1 
            else 0 
        end as is_anomaly_label
        
    from assignment_balances ab
    left join variance_analysis va 
        on ab.assignment_id = va.assignment_id 
        and ab.period_id = va.period_id
    left join assignment_stats ast on ab.assignment_id = ast.assignment_id
    left join variance_stats vs on ab.assignment_id = vs.assignment_id
    left join entities e on ab.entity_id = e.entity_id
    left join periods p on ab.period_id = p.period_id
    where ast.total_periods >= 3
)

select
    assignment_id,
    entity_id,
    period_id,
    period_end_date,
    period_year,
    period_quarter,
    period_month_num,
    assignment_type,
    
    coalesce(balance_gl, 0) as balance_gl,
    coalesce(balance_bank, 0) as balance_bank,
    coalesce(balance_subledger, 0) as balance_subledger,
    coalesce(gl_bank_variance, 0) as gl_bank_variance,
    coalesce(period_variance, 0) as period_variance,
    coalesce(period_abs_variance, 0) as period_abs_variance,
    coalesce(balance_gl_diff, 0) as balance_gl_diff,
    coalesce(balance_bank_diff, 0) as balance_bank_diff,
    
    coalesce(hist_avg_gl_balance, 0) as hist_avg_gl_balance,
    coalesce(hist_stddev_gl_balance, 0) as hist_stddev_gl_balance,
    coalesce(hist_avg_bank_balance, 0) as hist_avg_bank_balance,
    coalesce(hist_avg_variance, 0) as hist_avg_variance,
    coalesce(hist_stddev_variance, 0) as hist_stddev_variance,
    coalesce(hist_high_variance_count, 0) as hist_high_variance_count,
    coalesce(hist_avg_abs_variance, 0) as hist_avg_abs_variance,
    coalesce(hist_stddev_abs_variance, 0) as hist_stddev_abs_variance,
    coalesce(hist_max_abs_variance, 0) as hist_max_abs_variance,
    coalesce(hist_critical_count, 0) as hist_critical_count,
    coalesce(hist_high_count, 0) as hist_high_count,
    
    coalesce(gl_balance_zscore, 0) as gl_balance_zscore,
    coalesce(variance_zscore, 0) as variance_zscore,
    coalesce(abs_variance_zscore, 0) as abs_variance_zscore,
    coalesce(gl_bank_diff, 0) as gl_bank_diff,
    coalesce(variance_to_gl_ratio, 0) as variance_to_gl_ratio,
    coalesce(gl_period_change, 0) as gl_period_change,
    
    coalesce(entity_type, 0) as entity_type,
    coalesce(ownership, 0) as ownership,
    coalesce(hierarchy_depth, 0) as hierarchy_depth,
    
    reconciliation_status,
    variance_severity,
    variance_direction,
    is_anomaly_label,
    
    current_timestamp() as feature_timestamp
    
from period_features
where period_abs_variance is not null
  );

