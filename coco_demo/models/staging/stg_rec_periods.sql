WITH source AS (
    SELECT * FROM {{ source('customer_a_data', 'rec_periods') }}
)

SELECT
    PKID AS period_id,
    PERIOD_END_DATE,
    DATE_TRUNC('MONTH', PERIOD_END_DATE) AS period_month,
    YEAR(PERIOD_END_DATE) AS period_year,
    QUARTER(PERIOD_END_DATE) AS period_quarter,
    MONTHNAME(PERIOD_END_DATE) AS period_month_name,
    DB_INSERT_DATE AS created_at,
    DB_UPDATE_DATE AS updated_at
FROM source
