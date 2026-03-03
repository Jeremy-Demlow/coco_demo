





with validation_errors as (

    select
        entity_id, period_id
    from COCO_LIVE_DB.DBT.entity_reconciliation_summary
    group by entity_id, period_id
    having count(*) > 1

)

select *
from validation_errors


