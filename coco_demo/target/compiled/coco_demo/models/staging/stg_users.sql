WITH source AS (
    SELECT * FROM COCO_LIVE_DB.CUSTOMER_A_DATA.users
)

SELECT
    PKID AS user_id,
    FULL_NAME AS user_name,
    EMAIL AS user_email,
    DB_INSERT_DATE AS created_at,
    DB_UPDATE_DATE AS updated_at
FROM source