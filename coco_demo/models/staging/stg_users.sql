with source as (
    select * from {{ source('coco_live', 'users') }}
)

select
    pkid as user_id,
    full_name,
    email,
    db_insert_date,
    db_update_date
from source
