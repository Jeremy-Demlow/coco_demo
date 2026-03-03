
    
    

with child as (
    select period_id as from_field
    from COCO_LIVE_DB.DBT_STAGING.stg_rec_period_information
    where period_id is not null
),

parent as (
    select period_id as to_field
    from COCO_LIVE_DB.DBT_STAGING.stg_rec_periods
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


