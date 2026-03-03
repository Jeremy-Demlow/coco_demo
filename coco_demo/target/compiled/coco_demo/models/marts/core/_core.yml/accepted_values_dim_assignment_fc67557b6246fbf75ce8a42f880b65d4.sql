
    
    

with all_values as (

    select
        assignment_category as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT.dim_assignment
    group by assignment_category

)

select *
from all_values
where value_field not in (
    'Consolidated','Group','Standard'
)


