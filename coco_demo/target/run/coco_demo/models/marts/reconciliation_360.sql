
  create or replace   view COCO_LIVE_DB.DBT.reconciliation_360
  
   as (
    WITH assignments AS (
    SELECT * FROM COCO_LIVE_DB.DBT.stg_rec_assignments
),

entities AS (
    SELECT * FROM COCO_LIVE_DB.DBT.stg_org_entities
),

period_info AS (
    SELECT * FROM COCO_LIVE_DB.DBT.stg_rec_period_information
),

periods AS (
    SELECT * FROM COCO_LIVE_DB.DBT.stg_rec_periods
),

reconciliations AS (
    SELECT * FROM COCO_LIVE_DB.DBT.stg_rec_reconciliations
),

variance AS (
    SELECT * FROM COCO_LIVE_DB.DBT.stg_var_activity
),

recon_counts AS (
    SELECT
        assignment_id,
        period_id,
        COUNT(*) AS reconciliation_count,
        SUM(COALESCE(AMOUNT_UNIDENTIFIED, 0)) AS total_unidentified_amount
    FROM reconciliations
    GROUP BY 1, 2
),

variance_agg AS (
    SELECT
        assignment_id,
        period_id,
        SUM(ABS(COALESCE(total_variance, 0))) AS total_abs_variance,
        AVG(total_variance) AS avg_variance,
        MAX(ABS(total_variance)) AS max_variance
    FROM variance
    GROUP BY 1, 2
)

SELECT
    a.assignment_id,
    a.assignment_key,
    a.assignment_type,
    a.account_combination,
    a.currency,
    a.description AS assignment_description,
    a.is_group_assignment,
    a.is_consolidated_account,
    a.segment1,
    a.segment2,
    a.segment3,
    a.segment4,
    a.segment5,
    
    e.entity_id,
    e.entity_code,
    e.entity_name,
    e.entity_type,
    e.hierarchy_depth,
    e.parent_name AS parent_entity_name,
    e.financial_review_required,
    
    p.period_id,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_name,
    
    pi.is_active,
    pi.has_activity,
    pi.is_key_account,
    pi.purpose,
    pi.reconciliation_procedure,
    pi.recon_frequency,
    
    pi.balance_gl,
    pi.balance_gl_base,
    pi.balance_bank,
    pi.balance_bank_base,
    pi.balance_subledger,
    pi.balance_subledger_base,
    pi.balance_estimate,
    pi.balance_estimate_base,
    pi.balance_forecast,
    pi.balance_forecast_base,
    
    ABS(COALESCE(pi.balance_gl, 0) - COALESCE(pi.balance_bank, 0)) AS gl_bank_difference,
    ABS(COALESCE(pi.balance_gl, 0) - COALESCE(pi.balance_subledger, 0)) AS gl_subledger_difference,
    
    COALESCE(rc.reconciliation_count, 0) AS reconciliation_count,
    COALESCE(rc.total_unidentified_amount, 0) AS total_unidentified_amount,
    
    COALESCE(va.total_abs_variance, 0) AS total_abs_variance,
    va.avg_variance,
    va.max_variance,
    
    CASE 
        WHEN pi.is_active AND COALESCE(va.total_abs_variance, 0) = 0 THEN 'Fully Reconciled'
        WHEN pi.is_active AND COALESCE(va.total_abs_variance, 0) < 1000 THEN 'Minor Variance'
        WHEN pi.is_active AND COALESCE(va.total_abs_variance, 0) < 10000 THEN 'Moderate Variance'
        WHEN pi.is_active THEN 'High Variance'
        ELSE 'Inactive'
    END AS reconciliation_status,
    
    pi.last_update_date,
    pi.account_balance_last_update_date,
    pi.updated_at

FROM period_info pi
INNER JOIN assignments a ON pi.assignment_id = a.assignment_id
LEFT JOIN entities e ON a.entity_id = e.entity_id
INNER JOIN periods p ON pi.period_id = p.period_id
LEFT JOIN recon_counts rc ON pi.assignment_id = rc.assignment_id AND pi.period_id = rc.period_id
LEFT JOIN variance_agg va ON pi.assignment_id = va.assignment_id AND pi.period_id = va.period_id
  );

