
    
    

with child as (
    select entity_id as from_field
    from COCO_LIVE_DB.DBT_STAGING.stg_rec_assignments
    where entity_id is not null
),

parent as (
    select entity_id as to_field
    from COCO_LIVE_DB.DBT_STAGING.stg_org_entities
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


