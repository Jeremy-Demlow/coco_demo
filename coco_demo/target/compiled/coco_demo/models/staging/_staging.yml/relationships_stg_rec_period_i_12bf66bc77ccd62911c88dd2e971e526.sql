
    
    

with child as (
    select assignment_id as from_field
    from COCO_LIVE_DB.DBT_STAGING.stg_rec_period_information
    where assignment_id is not null
),

parent as (
    select assignment_id as to_field
    from COCO_LIVE_DB.DBT_STAGING.stg_rec_assignments
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


