





with validation_errors as (

    select
        assignment_id, period_id
    from COCO_LIVE_DB.DBT.reconciliation_360
    group by assignment_id, period_id
    having count(*) > 1

)

select *
from validation_errors


