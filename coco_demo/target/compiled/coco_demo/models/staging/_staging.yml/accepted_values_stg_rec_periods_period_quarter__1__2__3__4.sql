
    
    

with all_values as (

    select
        period_quarter as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT_STAGING.stg_rec_periods
    group by period_quarter

)

select *
from all_values
where value_field not in (
    '1','2','3','4'
)


