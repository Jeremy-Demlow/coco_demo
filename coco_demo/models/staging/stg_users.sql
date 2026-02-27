select
    pkid as user_id,
    full_name,
    email,
    db_insert_date as created_at,
    db_update_date as updated_at
from {{ source('replica', 'users') }}
