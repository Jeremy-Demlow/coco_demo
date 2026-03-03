{{
    config(
        materialized='table',
        unique_key='reconciliation_fact_key'
    )
}}

WITH fct AS (
    SELECT * FROM {{ ref('fct_reconciliation') }}
),

dim_assignment AS (
    SELECT * FROM {{ ref('dim_assignment') }}
),

dim_period AS (
    SELECT * FROM {{ ref('dim_period') }}
)

SELECT
    f.reconciliation_fact_key,
    
    f.assignment_id,
    a.assignment_code,
    a.assignment_type,
    a.account_combination,
    a.assignment_description,
    a.currency,
    a.assignment_category,
    a.review_priority,
    a.is_group_assignment,
    a.is_consolidated_account,
    a.segment1,
    a.segment2,
    a.segment3,
    a.segment4,
    a.segment5,
    a.account_hierarchy,
    
    a.entity_id,
    a.entity_code,
    a.entity_name,
    a.entity_type,
    a.hierarchy_depth,
    a.parent_entity_name,
    a.financial_review_required,
    
    f.period_id,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_name,
    p.year_quarter_label,
    p.year_month_label,
    p.is_year_end,
    p.is_quarter_end,
    
    f.is_active,
    f.has_activity,
    f.is_key_account,
    f.purpose,
    f.reconciliation_procedure,
    f.recon_frequency,
    
    f.balance_gl,
    f.balance_gl_base,
    f.balance_bank,
    f.balance_bank_base,
    f.balance_subledger,
    f.balance_subledger_base,
    f.balance_estimate,
    f.balance_estimate_base,
    f.balance_forecast,
    f.balance_forecast_base,
    
    f.gl_bank_difference,
    f.gl_subledger_difference,
    f.gl_estimate_difference,
    f.gl_bank_variance_pct,
    
    f.reconciliation_count,
    f.total_unidentified_amount,
    
    f.total_abs_variance,
    f.avg_variance,
    f.max_variance,
    f.min_variance,
    
    f.reconciliation_status,
    f.reconciliation_health_score,
    
    f.last_update_date,
    f.account_balance_last_update_date,
    f.record_updated_at

FROM fct f
INNER JOIN dim_assignment a ON f.assignment_key = a.assignment_key
INNER JOIN dim_period p ON f.period_key = p.period_key
