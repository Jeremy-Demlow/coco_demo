with source as (
    select * from {{ source('coco_live', 'comment_details') }}
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
