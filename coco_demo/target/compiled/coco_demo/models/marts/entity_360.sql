

WITH entity_base AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.stg_org_entities
),

assignments AS (
    SELECT * FROM COCO_LIVE_DB.DBT_MARTS.stg_rec_assignments
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
),

entity_assignment_counts AS (
    SELECT
        entity_id,
        COUNT(DISTINCT assignment_id) AS total_assignments,
        COUNT(DISTINCT CASE WHEN assignment_type = 'Balance' THEN assignment_id END) AS balance_assignments,
        COUNT(DISTINCT CASE WHEN assignment_type = 'Flux' THEN assignment_id END) AS flux_assignments,
        COUNT(DISTINCT CASE WHEN assignment_type = 'Activity' THEN assignment_id END) AS activity_assignments,
        COUNT(DISTINCT currency) AS currency_count
    FROM assignments
    GROUP BY entity_id
),

entity_period_metrics AS (
    SELECT
        a.entity_id,
        pi.period_id,
        COUNT(DISTINCT a.assignment_id) AS period_assignment_count,
        SUM(CASE WHEN pi.is_active = 1 THEN 1 ELSE 0 END) AS active_assignments,
        SUM(CASE WHEN pi.is_active = 0 THEN 1 ELSE 0 END) AS inactive_assignments,
        SUM(pi.balance_gl) AS total_balance_gl,
        SUM(pi.balance_gl_base) AS total_balance_gl_base,
        SUM(pi.balance_bank) AS total_balance_bank,
        SUM(pi.balance_bank_base) AS total_balance_bank_base,
        SUM(pi.balance_subledger) AS total_balance_subledger,
        AVG(pi.balance_gl) AS avg_balance_gl,
        SUM(CASE WHEN pi.is_key_account = 1 THEN 1 ELSE 0 END) AS key_account_count
    FROM assignments a
    INNER JOIN period_info pi ON a.assignment_id = pi.assignment_id
    GROUP BY a.entity_id, pi.period_id
),

entity_variance_metrics AS (
    SELECT
        a.entity_id,
        vs.period_id,
        SUM(vs.total_absolute_variance) AS total_variance,
        SUM(vs.total_gl_variance) AS total_gl_variance,
        SUM(vs.total_bank_variance) AS total_bank_variance,
        AVG(vs.avg_variance) AS avg_variance,
        MAX(vs.max_variance) AS max_single_variance
    FROM assignments a
    INNER JOIN variance_summary vs ON a.assignment_id = vs.assignment_id
    GROUP BY a.entity_id, vs.period_id
),

entity_reconciliation_metrics AS (
    SELECT
        a.entity_id,
        rs.period_id,
        SUM(rs.reconciliation_count) AS total_reconciliations,
        SUM(rs.proof_reconciliation_count) AS proof_reconciliations,
        SUM(rs.total_bank_calc_diff) AS total_unreconciled_amount
    FROM assignments a
    INNER JOIN reconciliation_summary rs ON a.assignment_id = rs.assignment_id
    GROUP BY a.entity_id, rs.period_id
)

SELECT
    e.entity_id,
    e.entity_code,
    e.entity_name,
    e.entity_description,
    e.entity_type,
    e.parent_id,
    e.parent_name,
    e.hierarchy_depth,
    e.hierarchy_lineage,
    e.ownership_percentage,
    e.has_children,
    e.financial_review_required,
    
    p.period_id,
    p.period_end_date,
    p.period_year,
    p.period_month_num,
    p.period_quarter,
    
    COALESCE(eac.total_assignments, 0) AS total_assignments,
    COALESCE(eac.balance_assignments, 0) AS balance_assignments,
    COALESCE(eac.flux_assignments, 0) AS flux_assignments,
    COALESCE(eac.activity_assignments, 0) AS activity_assignments,
    COALESCE(eac.currency_count, 0) AS currency_count,
    
    COALESCE(epm.period_assignment_count, 0) AS period_assignment_count,
    COALESCE(epm.active_assignments, 0) AS active_assignments,
    COALESCE(epm.inactive_assignments, 0) AS inactive_assignments,
    COALESCE(epm.total_balance_gl, 0) AS total_balance_gl,
    COALESCE(epm.total_balance_gl_base, 0) AS total_balance_gl_base,
    COALESCE(epm.total_balance_bank, 0) AS total_balance_bank,
    COALESCE(epm.total_balance_bank_base, 0) AS total_balance_bank_base,
    COALESCE(epm.total_balance_subledger, 0) AS total_balance_subledger,
    COALESCE(epm.avg_balance_gl, 0) AS avg_balance_gl,
    COALESCE(epm.key_account_count, 0) AS key_account_count,
    
    COALESCE(evm.total_variance, 0) AS total_variance,
    COALESCE(evm.total_gl_variance, 0) AS total_gl_variance,
    COALESCE(evm.total_bank_variance, 0) AS total_bank_variance,
    COALESCE(evm.avg_variance, 0) AS avg_variance,
    COALESCE(evm.max_single_variance, 0) AS max_single_variance,
    
    COALESCE(erm.total_reconciliations, 0) AS total_reconciliations,
    COALESCE(erm.proof_reconciliations, 0) AS proof_reconciliations,
    COALESCE(erm.total_unreconciled_amount, 0) AS total_unreconciled_amount,
    
    CASE 
        WHEN COALESCE(epm.period_assignment_count, 0) = 0 THEN 0
        ELSE ROUND(COALESCE(epm.active_assignments, 0) * 100.0 / epm.period_assignment_count, 2)
    END AS assignment_completion_rate,
    
    CASE
        WHEN COALESCE(evm.total_variance, 0) > 100000 THEN 'High'
        WHEN COALESCE(evm.total_variance, 0) > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS variance_risk_level,
    
    CURRENT_TIMESTAMP() AS dbt_updated_at

FROM entity_base e
CROSS JOIN periods p
LEFT JOIN entity_assignment_counts eac ON e.entity_id = eac.entity_id
LEFT JOIN entity_period_metrics epm ON e.entity_id = epm.entity_id AND p.period_id = epm.period_id
LEFT JOIN entity_variance_metrics evm ON e.entity_id = evm.entity_id AND p.period_id = evm.period_id
LEFT JOIN entity_reconciliation_metrics erm ON e.entity_id = erm.entity_id AND p.period_id = erm.period_id