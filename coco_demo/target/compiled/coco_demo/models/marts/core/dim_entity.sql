

WITH entity_source AS (
    SELECT * FROM COCO_LIVE_DB.DBT_STAGING.stg_org_entities
),

entity_with_surrogate AS (
    SELECT
        md5(cast(coalesce(cast(entity_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS entity_key,
        
        entity_id,
        entity_code,
        entity_name,
        entity_description,
        entity_type,
        
        parent_id,
        parent_name,
        hierarchy_depth,
        hierarchy_lineage,
        has_children,
        
        ownership,
        consolidation_ownership,
        consolidation_method_rule_id,
        
        financial_review_required,
        include_in_intercompany,
        
        CASE hierarchy_depth
            WHEN 1 THEN 'Corporate'
            WHEN 2 THEN 'Region'
            WHEN 3 THEN 'Business Unit'
            WHEN 4 THEN 'Department'
            ELSE 'Sub-Department'
        END AS hierarchy_level_name,
        
        CASE 
            WHEN has_children THEN 'Parent'
            ELSE 'Leaf'
        END AS node_type,
        
        created_at AS valid_from,
        updated_at AS valid_to,
        TRUE AS is_current
        
    FROM entity_source
)

SELECT * FROM entity_with_surrogate