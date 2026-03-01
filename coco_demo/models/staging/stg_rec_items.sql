with source as (
    select * from {{ source('coco_live', 'rec_items') }}
)

select
    pkid as item_id,
    description as item_description,
    item_type,
    currency,
    amount,
    item_open_date,
    delete_flag,
    db_insert_date,
    db_update_date
from source
where delete_flag = 0 or delete_flag is null
