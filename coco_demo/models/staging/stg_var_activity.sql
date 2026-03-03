WITH source AS (
    SELECT * FROM {{ source('customer_a_data', 'var_activity') }}
)

SELECT
    VAR_ACTIVITY_ID AS variance_activity_id,
    ASSIGNMENT_ID,
    PERIOD_ID,
    PRIOR_PERIOD_ID,
    BALANCE_GL_DIFF AS gl_variance,
    BALANCE_GL_BASE_DIFF AS gl_variance_base,
    BALANCE_GL_FUNC_DIFF AS gl_variance_func,
    BALANCE_ESTIMATE_DIFF AS estimate_variance,
    BALANCE_ESTIMATE_BASE_DIFF AS estimate_variance_base,
    BALANCE_ESTIMATE_FUNC_DIFF AS estimate_variance_func,
    BALANCE_SUBLEDGER_DIFF AS subledger_variance,
    BALANCE_SUBLEDGER_BASE_DIFF AS subledger_variance_base,
    BALANCE_SUBLEDGER_FUNC_DIFF AS subledger_variance_func,
    BALANCE_BANK_DIFF AS bank_variance,
    BALANCE_BANK_BASE_DIFF AS bank_variance_base,
    BALANCE_BANK_FUNC_DIFF AS bank_variance_func,
    VARIANCE AS total_variance,
    VARIANCE_BASE AS total_variance_base,
    VARIANCE_FUNC AS total_variance_func,
    DB_INSERT_DATE AS created_at,
    DB_UPDATE_DATE AS updated_at
FROM source
