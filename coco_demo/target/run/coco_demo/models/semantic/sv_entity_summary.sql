create or replace semantic view COCO_LIVE_DB.DBT.sv_entity_summary
  

TABLES(
  ent AS COCO_LIVE_DB.DBT.entity_reconciliation_summary
)

DIMENSIONS(
  ent.entity_id AS entity_id,
  ent.entity_name AS entity_name,
  ent.entity_code AS entity_code,
  ent.parent_entity_name AS parent_entity_name,
  ent.hierarchy_depth AS hierarchy_depth,
  ent.period_end_date AS period_end_date,
  ent.period_year AS period_year,
  ent.period_quarter AS period_quarter,
  ent.period_month_name AS period_month_name,
  ent.total_assignments AS total_assignments,
  ent.active_assignments AS active_assignments,
  ent.key_accounts AS key_accounts,
  ent.total_gl_balance AS total_gl_balance,
  ent.total_bank_balance AS total_bank_balance,
  ent.total_variance AS total_variance,
  ent.reconciliation_completion_rate AS reconciliation_completion_rate,
  ent.fully_reconciled_count AS fully_reconciled_count,
  ent.high_variance_count AS high_variance_count
)

METRICS(
  avg_completion_rate AS AVG(ent.reconciliation_completion_rate),
  sum_variance AS SUM(ent.total_variance),
  entity_count AS COUNT(DISTINCT ent.entity_id),
  sum_assignments AS SUM(ent.total_assignments)
)

COMMENT = 'Entity-level reconciliation metrics for organizational performance analysis'