
    
    

with child as (
    select period_key as from_field
    from COCO_LIVE_DB.DBT.fct_reconciliation
    where period_key is not null
),

parent as (
    select period_key as to_field
    from COCO_LIVE_DB.DBT.dim_period
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


