
    
    

with all_values as (

    select
        node_type as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT.dim_entity
    group by node_type

)

select *
from all_values
where value_field not in (
    'Parent','Leaf'
)


