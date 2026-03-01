
  create or replace   view COCO_LIVE_DB.PUBLIC.stg_comment_details
  
   as (
    with source as (
    select * from COCO_LIVE_DB.CUSTOMER_A_DATA.comment_details
)

select
    comment_id,
    comment_desc,
    comment_type_id,
    user_id_orig,
    user_id_update,
    parent_id,
    internal as is_internal,
    date_orig,
    date_update,
    db_insert_date,
    db_update_date
from source
  );

