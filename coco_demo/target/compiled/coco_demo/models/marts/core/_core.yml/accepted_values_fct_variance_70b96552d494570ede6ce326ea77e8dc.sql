
    
    

with all_values as (

    select
        variance_severity as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT.fct_variance
    group by variance_severity

)

select *
from all_values
where value_field not in (
    'None','Minor','Moderate','High'
)


