WITH source AS (
    SELECT * FROM {{ source('customer_a_data', 'rec_assignments') }}
    WHERE DELETE_FLAG = FALSE OR DELETE_FLAG IS NULL
)

SELECT
    PKID AS assignment_id,
    ENTITY_ID,
    FINANCIAL_STATEMENT_ID,
    ASSIGNMENT_KEY,
    ASSIGNMENT_TYPE,
    COMBO_NAME AS account_combination,
    SEGMENT1,
    SEGMENT2,
    SEGMENT3,
    SEGMENT4,
    SEGMENT5,
    CURRENCY,
    TEAM_ID,
    DESCRIPTION,
    GROUP_ASSIGNMENT AS is_group_assignment,
    IS_CONSOLIDATED_ACCOUNT,
    VARIANCE_ASSIGNMENT_ID,
    DB_INSERT_DATE AS created_at,
    DB_UPDATE_DATE AS updated_at
FROM source
