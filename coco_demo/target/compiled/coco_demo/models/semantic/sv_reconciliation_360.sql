

TABLES(
  rec AS COCO_LIVE_DB.DBT.reconciliation_360
)

DIMENSIONS(
  rec.assignment_id AS assignment_id,
  rec.assignment_key AS assignment_key,
  rec.account_combination AS account_combination,
  rec.currency AS currency,
  rec.entity_name AS entity_name,
  rec.entity_code AS entity_code,
  rec.parent_entity_name AS parent_entity_name,
  rec.hierarchy_depth AS hierarchy_depth,
  rec.reconciliation_status AS reconciliation_status,
  rec.assignment_type AS assignment_type,
  rec.purpose AS purpose,
  rec.is_active AS is_active,
  rec.is_key_account AS is_key_account,
  rec.segment1 AS segment1,
  rec.segment2 AS segment2,
  rec.segment3 AS segment3,
  rec.period_end_date AS period_end_date,
  rec.period_year AS period_year,
  rec.period_quarter AS period_quarter,
  rec.period_month_name AS period_month_name,
  rec.balance_gl AS balance_gl,
  rec.balance_bank AS balance_bank,
  rec.balance_subledger AS balance_subledger,
  rec.balance_estimate AS balance_estimate,
  rec.balance_forecast AS balance_forecast,
  rec.gl_bank_difference AS gl_bank_difference,
  rec.gl_subledger_difference AS gl_subledger_difference,
  rec.total_abs_variance AS total_abs_variance,
  rec.max_variance AS max_variance,
  rec.reconciliation_count AS reconciliation_count,
  rec.total_unidentified_amount AS total_unidentified_amount
)

METRICS(
  total_gl_balance AS SUM(rec.balance_gl),
  total_bank_balance AS SUM(rec.balance_bank),
  total_variance_amount AS SUM(rec.total_abs_variance),
  average_variance AS AVG(rec.total_abs_variance),
  assignment_count AS COUNT(DISTINCT rec.assignment_id),
  active_assignment_count AS SUM(CASE WHEN rec.is_active THEN 1 ELSE 0 END),
  fully_reconciled_count AS SUM(CASE WHEN rec.reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END),
  high_variance_count AS SUM(CASE WHEN rec.reconciliation_status = 'High Variance' THEN 1 ELSE 0 END),
  completion_rate AS ROUND(100.0 * SUM(CASE WHEN rec.reconciliation_status = 'Fully Reconciled' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN rec.is_active THEN 1 ELSE 0 END), 0), 2),
  key_account_count AS SUM(CASE WHEN rec.is_key_account THEN 1 ELSE 0 END)
)

COMMENT = 'Comprehensive 360-degree view of reconciliation assignments for Cortex Analyst queries'