{{
    config(
        materialized='table',
        unique_key='variance_fact_key',
        cluster_by=['period_key']
    )
}}

WITH variance_source AS (
    SELECT * FROM {{ ref('stg_var_activity') }}
),

dim_assignment AS (
    SELECT assignment_key, assignment_id FROM {{ ref('dim_assignment') }}
),

dim_period AS (
    SELECT period_key, period_id FROM {{ ref('dim_period') }}
),

fact_variance AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['v.variance_activity_id']) }} AS variance_fact_key,
        
        da.assignment_key,
        dp.period_key,
        dp_prior.period_key AS prior_period_key,
        
        v.variance_activity_id,
        v.assignment_id,
        v.period_id,
        v.prior_period_id,
        
        v.gl_variance,
        v.gl_variance_base,
        v.gl_variance_func,
        
        v.bank_variance,
        v.bank_variance_base,
        v.bank_variance_func,
        
        v.subledger_variance,
        v.subledger_variance_base,
        v.subledger_variance_func,
        
        v.estimate_variance,
        v.estimate_variance_base,
        v.estimate_variance_func,
        
        v.total_variance,
        v.total_variance_base,
        v.total_variance_func,
        
        ABS(COALESCE(v.total_variance, 0)) AS absolute_variance,
        
        CASE 
            WHEN v.total_variance > 0 THEN 'Positive'
            WHEN v.total_variance < 0 THEN 'Negative'
            ELSE 'Zero'
        END AS variance_direction,
        
        CASE 
            WHEN ABS(COALESCE(v.total_variance, 0)) = 0 THEN 'None'
            WHEN ABS(COALESCE(v.total_variance, 0)) < {{ var('variance_threshold_minor') }} THEN 'Minor'
            WHEN ABS(COALESCE(v.total_variance, 0)) < {{ var('variance_threshold_moderate') }} THEN 'Moderate'
            ELSE 'High'
        END AS variance_severity,
        
        v.created_at,
        v.updated_at AS record_updated_at,
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM variance_source v
    INNER JOIN dim_assignment da ON v.assignment_id = da.assignment_id
    INNER JOIN dim_period dp ON v.period_id = dp.period_id
    LEFT JOIN dim_period dp_prior ON v.prior_period_id = dp_prior.period_id
)

SELECT * FROM fact_variance
