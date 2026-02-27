

WITH assignments AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.stg_rec_assignments
),

entities AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.stg_org_entities
),

periods AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.stg_rec_periods
),

period_info AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.stg_rec_period_information
),

reconciliation_summary AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.int_reconciliation_summary
),

variance_summary AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.int_assignment_variance_summary
)

SELECT
    a.assignment_id,
    a.assignment_key,
    a.assignment_type,
    a.combo_name,
    a.assignment_description,
    a.segment1,
    a.segment2,
    a.segment3,
    a.currency,
    a.is_group_assignment,
    a.is_consolidated_account,
    
    e.entity_id,
    e.entity_code,
    e.entity_name,
    e.entity_type,
    e.parent_name AS entity_parent_name,
    e.hierarchy_depth AS entity_hierarchy_depth,
    e.ownership_percentage AS entity_ownership_pct,
    
    p.period_id,
    p.period_end_date,
    p.period_year,
    p.period_month_num,
    p.period_quarter,
    
    pi.is_active,
    pi.activity_in_period,
    pi.is_key_account,
    pi.is_elimination_account,
    
    pi.balance_gl,
    pi.balance_gl_base,
    pi.balance_gl_func,
    pi.balance_bank,
    pi.balance_bank_base,
    pi.balance_bank_func,
    pi.balance_subledger,
    pi.balance_subledger_base,
    pi.balance_subledger_func,
    pi.balance_estimate,
    pi.balance_estimate_base,
    pi.balance_forecast,
    pi.balance_forecast_base,
    
    COALESCE(rs.reconciliation_count, 0) AS reconciliation_count,
    COALESCE(rs.proof_reconciliation_count, 0) AS proof_reconciliation_count,
    COALESCE(rs.total_balance_bank, 0) AS rec_total_balance_bank,
    COALESCE(rs.total_balance_calculated, 0) AS rec_total_balance_calculated,
    COALESCE(rs.total_bank_calc_diff, 0) AS unreconciled_amount,
    
    COALESCE(vs.variance_record_count, 0) AS variance_record_count,
    COALESCE(vs.total_absolute_variance, 0) AS total_variance,
    COALESCE(vs.total_absolute_variance_base, 0) AS total_variance_base,
    COALESCE(vs.avg_variance, 0) AS avg_variance,
    COALESCE(vs.max_variance, 0) AS max_variance,
    COALESCE(vs.total_gl_variance, 0) AS gl_variance,
    COALESCE(vs.total_bank_variance, 0) AS bank_variance,
    
    CASE WHEN pi.is_active = 1 THEN 'Active' ELSE 'Inactive' END AS status,
    
    CASE
        WHEN COALESCE(vs.total_absolute_variance, 0) > 50000 THEN 'High'
        WHEN COALESCE(vs.total_absolute_variance, 0) > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS variance_risk,
    
    CASE
        WHEN COALESCE(rs.total_bank_calc_diff, 0) > 10000 THEN 'Needs Review'
        WHEN pi.is_active = 1 AND COALESCE(rs.reconciliation_count, 0) = 0 THEN 'Pending'
        WHEN pi.is_active = 1 THEN 'On Track'
        ELSE 'Complete'
    END AS reconciliation_status,
    
    CURRENT_TIMESTAMP() AS dbt_updated_at

FROM assignments a
INNER JOIN entities e ON a.entity_id = e.entity_id
CROSS JOIN periods p
LEFT JOIN period_info pi ON a.assignment_id = pi.assignment_id AND p.period_id = pi.period_id
LEFT JOIN reconciliation_summary rs ON a.assignment_id = rs.assignment_id AND p.period_id = rs.period_id
LEFT JOIN variance_summary vs ON a.assignment_id = vs.assignment_id AND p.period_id = vs.period_id
WHERE pi.period_info_id IS NOT NULL