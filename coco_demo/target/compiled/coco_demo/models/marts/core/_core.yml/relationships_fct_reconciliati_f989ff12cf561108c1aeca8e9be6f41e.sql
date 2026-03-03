
    
    

with child as (
    select assignment_key as from_field
    from COCO_LIVE_DB.DBT.fct_reconciliation
    where assignment_key is not null
),

parent as (
    select assignment_key as to_field
    from COCO_LIVE_DB.DBT.dim_assignment
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


