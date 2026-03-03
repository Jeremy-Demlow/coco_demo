
  create or replace   view COCO_LIVE_DB.DBT.stg_org_entities
  
   as (
    WITH source AS (
    SELECT * FROM COCO_LIVE_DB.CUSTOMER_A_DATA.org_entities
    WHERE DELETE_FLAG = FALSE OR DELETE_FLAG IS NULL
)

SELECT
    ID AS entity_id,
    CODE AS entity_code,
    NAME AS entity_name,
    DESCRIPTION AS entity_description,
    TYPE AS entity_type,
    PARENT_ID,
    PARENT_NAME,
    DEPTH AS hierarchy_depth,
    LINEAGE AS hierarchy_lineage,
    HAS_CHILDREN,
    OWNERSHIP,
    CONSOLIDATION_OWNERSHIP,
    CONSOLIDATION_METHOD_RULE_ID,
    FINANCIAL_REVIEW_REQUIRED,
    INCLUDE_IN_INTERCOMPANY,
    DB_INSERT_DATE AS created_at,
    DB_UPDATE_DATE AS updated_at
FROM source
  );

