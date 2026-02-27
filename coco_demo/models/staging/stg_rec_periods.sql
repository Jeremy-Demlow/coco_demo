SELECT
    pkid AS period_id,
    period_end_date,
    DATE_TRUNC('month', period_end_date) AS period_month,
    YEAR(period_end_date) AS period_year,
    MONTH(period_end_date) AS period_month_num,
    QUARTER(period_end_date) AS period_quarter,
    db_insert_date AS created_at,
    db_update_date AS updated_at
FROM {{ source('customer_a_data', 'rec_periods') }}
