{{ config(materialized='semantic_view') }}

TABLES(
  prd AS {{ ref('period_reconciliation_summary') }}
)

DIMENSIONS(
  prd.period_id AS period_id,
  prd.period_end_date AS period_end_date,
  prd.period_year AS period_year,
  prd.period_quarter AS period_quarter,
  prd.period_month_name AS period_month_name,
  prd.total_assignments AS total_assignments,
  prd.active_assignments AS active_assignments,
  prd.entities_with_activity AS entities_with_activity,
  prd.fully_reconciled AS fully_reconciled,
  prd.high_variance AS high_variance,
  prd.moderate_variance AS moderate_variance,
  prd.total_variance AS total_variance,
  prd.completion_rate_pct AS completion_rate_pct,
  prd.variance_alert_rate_pct AS variance_alert_rate_pct,
  prd.total_gl_balance AS total_gl_balance,
  prd.total_unidentified AS total_unidentified
)

METRICS(
  avg_completion AS AVG(prd.completion_rate_pct),
  sum_variance AS SUM(prd.total_variance),
  period_count AS COUNT(DISTINCT prd.period_id),
  sum_assignments AS SUM(prd.total_assignments)
)

COMMENT = 'Period-level dashboard metrics for reconciliation health and variance trends'
