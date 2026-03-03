

WITH assignment_entity AS (
    SELECT
        a.assignment_id,
        a.entity_id,
        a.assignment_key,
        a.assignment_type,
        a.account_combination,
        a.currency,
        a.description AS assignment_description,
        a.is_group_assignment,
        a.is_consolidated_account,
        a.segment1,
        a.segment2,
        a.segment3,
        a.segment4,
        a.segment5,
        a.team_id,
        a.financial_statement_id,
        
        e.entity_code,
        e.entity_name,
        e.entity_description,
        e.entity_type,
        e.hierarchy_depth,
        e.hierarchy_lineage,
        e.parent_id,
        e.parent_name,
        e.has_children,
        e.ownership,
        e.consolidation_ownership,
        e.financial_review_required,
        e.include_in_intercompany
        
    FROM COCO_LIVE_DB.DBT_STAGING.stg_rec_assignments a
    LEFT JOIN COCO_LIVE_DB.DBT_STAGING.stg_org_entities e
        ON a.entity_id = e.entity_id
)

SELECT * FROM assignment_entity