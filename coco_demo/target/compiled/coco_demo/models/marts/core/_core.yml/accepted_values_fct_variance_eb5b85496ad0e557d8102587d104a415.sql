
    
    

with all_values as (

    select
        variance_direction as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT.fct_variance
    group by variance_direction

)

select *
from all_values
where value_field not in (
    'Positive','Negative','Zero'
)


