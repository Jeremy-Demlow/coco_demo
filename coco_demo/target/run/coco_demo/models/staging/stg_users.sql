
  create or replace   view COCO_LIVE_DB.DBT_MARTS.stg_users
  
   as (
    SELECT
    pkid AS user_id,
    full_name AS user_name,
    email AS user_email,
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM COCO_LIVE_DB.CUSTOMER_A_DATA.users
  );

