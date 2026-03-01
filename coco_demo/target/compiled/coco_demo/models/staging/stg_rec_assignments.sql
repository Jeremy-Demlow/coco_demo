with source as (
    select * from COCO_LIVE_DB.CUSTOMER_A_DATA.rec_assignments
)

select
    pkid as assignment_id,
    entity_id,
    financial_statement_id,
    assignment_key,
    assignment_type,
    combo_name,
    description as assignment_description,
    currency,
    rate_type,
    team_id,
    group_assignment,
    is_consolidated_account,
    variance_assignment_id,
    segment1,
    segment2,
    segment3,
    allow_multi_cncy_group,
    delete_flag,
    db_insert_date,
    db_update_date
from source
where delete_flag = 0 or delete_flag is null