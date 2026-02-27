SELECT
    pkid AS user_id,
    full_name AS user_name,
    email AS user_email,
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM {{ source('customer_a_data', 'users') }}
