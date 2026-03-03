
    
    

with child as (
    select ENTITY_ID as from_field
    from COCO_LIVE_DB.CUSTOMER_A_DATA.rec_assignments
    where ENTITY_ID is not null
),

parent as (
    select ID as to_field
    from COCO_LIVE_DB.CUSTOMER_A_DATA.org_entities
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


