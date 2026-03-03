

WITH assignment_source AS (
    SELECT * FROM COCO_LIVE_DB.DBT_INTERMEDIATE.int_assignment_entity
),

assignment_with_surrogate AS (
    SELECT
        md5(cast(coalesce(cast(assignment_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS assignment_key,
        
        assignment_id,
        entity_id,
        
        assignment_key AS assignment_code,
        assignment_type,
        account_combination,
        assignment_description,
        
        currency,
        team_id,
        financial_statement_id,
        
        segment1,
        segment2,
        segment3,
        segment4,
        segment5,
        
        COALESCE(segment1, '') || '-' || 
        COALESCE(segment2, '') || '-' || 
        COALESCE(segment3, '') AS account_hierarchy,
        
        is_group_assignment,
        is_consolidated_account,
        
        entity_code,
        entity_name,
        entity_type,
        hierarchy_depth,
        parent_name AS parent_entity_name,
        financial_review_required,
        
        CASE 
            WHEN is_consolidated_account THEN 'Consolidated'
            WHEN is_group_assignment THEN 'Group'
            ELSE 'Standard'
        END AS assignment_category,
        
        CASE 
            WHEN financial_review_required THEN 'High'
            WHEN is_consolidated_account THEN 'Medium'
            ELSE 'Standard'
        END AS review_priority
        
    FROM assignment_source
)

SELECT * FROM assignment_with_surrogate