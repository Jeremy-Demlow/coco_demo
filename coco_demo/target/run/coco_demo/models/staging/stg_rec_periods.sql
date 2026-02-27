
  create or replace   view DBAPI_REPLICA_DB.PUBLIC.stg_rec_periods
  
   as (
    select
    pkid as period_id,
    period_end_date,
    date_trunc('month', period_end_date) as period_month,
    year(period_end_date) as period_year,
    quarter(period_end_date) as period_quarter,
    month(period_end_date) as period_month_num,
    db_insert_date as created_at,
    db_update_date as updated_at
from DBAPI_REPLICA_DB.CUSTOMER_A_DATA.rec_periods
  );

