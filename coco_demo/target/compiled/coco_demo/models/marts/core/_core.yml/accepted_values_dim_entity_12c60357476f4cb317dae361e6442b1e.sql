
    
    

with all_values as (

    select
        hierarchy_level_name as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT.dim_entity
    group by hierarchy_level_name

)

select *
from all_values
where value_field not in (
    'Corporate','Region','Business Unit','Department','Sub-Department'
)


