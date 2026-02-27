
  create or replace   view COCO_LIVE_DB.DBT_MARTS.stg_rec_assignments
  
   as (
    SELECT
    pkid AS assignment_id,
    entity_id,
    financial_statement_id,
    assignment_key,
    assignment_type,
    combo_name,
    description AS assignment_description,
    segment1,
    segment2,
    segment3,
    segment4,
    segment5,
    currency,
    rate_type,
    team_id,
    group_assignment AS is_group_assignment,
    is_consolidated_account,
    allow_multi_cncy_group,
    delete_flag AS is_deleted,
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM COCO_LIVE_DB.CUSTOMER_A_DATA.rec_assignments
WHERE delete_flag = 0
  );

