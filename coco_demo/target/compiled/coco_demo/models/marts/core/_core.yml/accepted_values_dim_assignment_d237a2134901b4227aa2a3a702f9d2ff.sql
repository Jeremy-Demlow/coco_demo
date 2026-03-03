
    
    

with all_values as (

    select
        review_priority as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT.dim_assignment
    group by review_priority

)

select *
from all_values
where value_field not in (
    'High','Medium','Standard'
)


