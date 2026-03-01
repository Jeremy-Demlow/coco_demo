with variance as (
    select * from COCO_LIVE_DB.PUBLIC.stg_var_activity
),

periods as (
    select * from COCO_LIVE_DB.PUBLIC.stg_rec_periods
)

select
    v.var_activity_id,
    v.assignment_id,
    v.period_id,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    v.prior_period_id,
    v.variance,
    v.variance_base,
    v.variance_func,
    v.balance_gl_diff,
    v.balance_bank_diff,
    v.balance_subledger_diff,
    v.balance_estimate_diff,
    abs(v.variance) as abs_variance,
    case
        when abs(v.variance) > 10000 then 'Critical'
        when abs(v.variance) > 5000 then 'High'
        when abs(v.variance) > 1000 then 'Medium'
        when abs(v.variance) > 0 then 'Low'
        else 'None'
    end as variance_severity,
    case
        when v.variance > 0 then 'Positive'
        when v.variance < 0 then 'Negative'
        else 'Zero'
    end as variance_direction
from variance v
inner join periods p on v.period_id = p.period_id