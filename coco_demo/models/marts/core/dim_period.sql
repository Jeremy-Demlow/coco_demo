{{
    config(
        materialized='table',
        unique_key='period_key'
    )
}}

WITH period_source AS (
    SELECT * FROM {{ ref('stg_rec_periods') }}
),

period_with_attributes AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['period_id']) }} AS period_key,
        
        period_id,
        period_end_date,
        period_month,
        period_year,
        period_quarter,
        period_month_name,
        
        DATE_TRUNC('year', period_end_date) AS fiscal_year_start,
        DATEADD('year', 1, DATE_TRUNC('year', period_end_date)) - 1 AS fiscal_year_end,
        
        'Q' || period_quarter::VARCHAR AS quarter_label,
        period_year::VARCHAR || '-Q' || period_quarter::VARCHAR AS year_quarter_label,
        period_year::VARCHAR || '-' || LPAD(MONTH(period_end_date)::VARCHAR, 2, '0') AS year_month_label,
        
        CASE 
            WHEN period_quarter IN (1, 2) THEN 'H1'
            ELSE 'H2'
        END AS half_year,
        
        CASE 
            WHEN MONTH(period_end_date) IN (1, 2, 3) THEN 'Q1'
            WHEN MONTH(period_end_date) IN (4, 5, 6) THEN 'Q2'
            WHEN MONTH(period_end_date) IN (7, 8, 9) THEN 'Q3'
            ELSE 'Q4'
        END AS calendar_quarter,
        
        CASE 
            WHEN MONTH(period_end_date) = 12 THEN TRUE
            ELSE FALSE
        END AS is_year_end,
        
        CASE 
            WHEN MONTH(period_end_date) IN (3, 6, 9, 12) THEN TRUE
            ELSE FALSE
        END AS is_quarter_end,
        
        ROW_NUMBER() OVER (ORDER BY period_end_date) AS period_sequence,
        
        LAG(period_id) OVER (ORDER BY period_end_date) AS prior_period_id,
        LEAD(period_id) OVER (ORDER BY period_end_date) AS next_period_id,
        
        LAG(period_end_date, 12) OVER (ORDER BY period_end_date) AS same_period_prior_year_date,
        
        created_at,
        updated_at
        
    FROM period_source
)

SELECT * FROM period_with_attributes
