WITH orphan_assignments AS (
    SELECT 
        a.assignment_id,
        a.entity_id
    FROM COCO_LIVE_DB.DBT_STAGING.stg_rec_assignments a
    LEFT JOIN COCO_LIVE_DB.DBT_STAGING.stg_org_entities e 
        ON a.entity_id = e.entity_id
    WHERE e.entity_id IS NULL
      AND a.entity_id IS NOT NULL
)

SELECT *
FROM orphan_assignments