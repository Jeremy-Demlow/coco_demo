
  create or replace   view COCO_LIVE_DB.PUBLIC.stg_org_entities
  
   as (
    with source as (
    select * from COCO_LIVE_DB.CUSTOMER_A_DATA.org_entities
)

select
    id as entity_id,
    code as entity_code,
    name as entity_name,
    description as entity_description,
    type as entity_type,
    parent_id,
    parent_name,
    ownership,
    depth,
    lineage,
    has_children,
    consolidation_method_rule_id,
    consolidation_ownership,
    financial_review_required,
    include_in_intercompany,
    delete_flag,
    db_insert_date,
    db_update_date
from source
where delete_flag = 0 or delete_flag is null
  );

