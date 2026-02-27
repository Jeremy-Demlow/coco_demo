
  create or replace   view COCO_LIVE_DB.DBT_MARTS.stg_org_entities
  
   as (
    SELECT
    id AS entity_id,
    code AS entity_code,
    name AS entity_name,
    description AS entity_description,
    type AS entity_type,
    parent_id,
    parent_name,
    depth AS hierarchy_depth,
    lineage AS hierarchy_lineage,
    ownership AS ownership_percentage,
    has_children,
    financial_review_required,
    include_in_intercompany,
    delete_flag AS is_deleted,
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM COCO_LIVE_DB.CUSTOMER_A_DATA.org_entities
WHERE delete_flag = 0
  );

