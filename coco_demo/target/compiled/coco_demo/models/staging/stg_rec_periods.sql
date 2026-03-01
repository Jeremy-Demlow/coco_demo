with source as (
    select * from COCO_LIVE_DB.CUSTOMER_A_DATA.rec_periods
)

select
    pkid as period_id,
    period_end_date,
    date_trunc('month', period_end_date) as period_month,
    year(period_end_date) as period_year,
    quarter(period_end_date) as period_quarter,
    month(period_end_date) as period_month_num,
    db_insert_date,
    db_update_date
from source