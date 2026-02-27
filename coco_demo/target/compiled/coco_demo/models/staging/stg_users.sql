select
    pkid as user_id,
    full_name,
    email,
    db_insert_date as created_at,
    db_update_date as updated_at
from DBAPI_REPLICA_DB.CUSTOMER_A_DATA.users