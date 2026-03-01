with source as (
    select * from COCO_LIVE_DB.CUSTOMER_A_DATA.users
)

select
    pkid as user_id,
    full_name,
    email,
    db_insert_date,
    db_update_date
from source