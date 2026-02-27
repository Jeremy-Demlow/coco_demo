
  create or replace   view DBAPI_REPLICA_DB.PUBLIC.stg_rec_assignments
  
   as (
    select
    pkid as assignment_id,
    entity_id,
    financial_statement_id,
    assignment_key,
    assignment_type,
    combo_name as account_combination,
    description as assignment_description,
    currency,
    rate_type,
    team_id,
    segment1, segment2, segment3, segment4, segment5,
    segment6, segment7, segment8, segment9, segment10,
    group_assignment as is_group_assignment,
    is_consolidated_account,
    variance_assignment_id,
    allow_multi_cncy_group,
    delete_flag as is_deleted,
    db_insert_date as created_at,
    db_update_date as updated_at
from DBAPI_REPLICA_DB.CUSTOMER_A_DATA.rec_assignments
where delete_flag = false or delete_flag is null
  );

