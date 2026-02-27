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
FROM {{ source('customer_a_data', 'rec_assignments') }}
WHERE delete_flag = 0
