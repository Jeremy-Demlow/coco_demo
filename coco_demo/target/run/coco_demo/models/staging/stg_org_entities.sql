
  create or replace   view DBAPI_REPLICA_DB.PUBLIC.stg_org_entities
  
   as (
    select
    id as entity_id,
    code as entity_code,
    name as entity_name,
    description as entity_description,
    parent_id,
    parent_name,
    depth as hierarchy_depth,
    lineage as hierarchy_lineage,
    has_children,
    max_child_level,
    type as entity_type,
    ownership,
    consolidation_method_rule_id,
    consolidation_ownership,
    financial_review_required,
    include_in_intercompany,
    delete_flag as is_deleted,
    db_insert_date as created_at,
    db_update_date as updated_at
from DBAPI_REPLICA_DB.CUSTOMER_A_DATA.org_entities
where delete_flag = false or delete_flag is null
  );

