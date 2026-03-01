create or replace semantic view COCO_LIVE_DB.PUBLIC.semantic_entity_360
  

TABLES(
    entities AS COCO_LIVE_DB.PUBLIC.mart_entity_360
        PRIMARY KEY (entity_id)
        WITH SYNONYMS ('organizations', 'companies', 'org units')
        COMMENT = 'Comprehensive 360 view of organizational entities with reconciliation health metrics',
    variance_summary AS COCO_LIVE_DB.PUBLIC.mart_variance_summary
        PRIMARY KEY (entity_id, period_id)
        WITH SYNONYMS ('variance trends', 'period variances')
        COMMENT = 'Period-by-period variance analysis by entity'
)

RELATIONSHIPS(
    variance_to_entity AS
        variance_summary (entity_id) REFERENCES entities (entity_id)
)

FACTS(
    entities.total_assignments AS entities.total_assignments,
    entities.periods_with_activity AS entities.periods_with_activity,
    entities.total_gl_balance AS entities.total_gl_balance,
    entities.total_bank_balance AS entities.total_bank_balance,
    entities.total_subledger_balance AS entities.total_subledger_balance,
    entities.total_gl_bank_variance AS entities.total_gl_bank_variance,
    entities.reconciled_count AS entities.reconciled_count,
    entities.high_variance_count AS entities.high_variance_count,
    entities.missing_data_count AS entities.missing_data_count,
    entities.reconciliation_completion_pct AS entities.reconciliation_completion_pct,
    entities.total_variance_amount AS entities.total_variance_amount,
    entities.avg_variance_amount AS entities.avg_variance_amount,
    entities.critical_variance_count AS entities.critical_variance_count,
    entities.high_severity_count AS entities.high_severity_count,
    entities.current_period_gl_balance AS entities.current_period_gl_balance,
    entities.current_period_bank_balance AS entities.current_period_bank_balance,
    entities.current_period_variance AS entities.current_period_variance,
    entities.current_reconciled_count AS entities.current_reconciled_count,
    entities.current_unreconciled_count AS entities.current_unreconciled_count,
    entities.ownership AS entities.ownership,
    entities.hierarchy_depth AS entities.hierarchy_depth,
    variance_summary.assignments_with_variance AS variance_summary.assignments_with_variance,
    variance_summary.total_variance AS variance_summary.total_variance,
    variance_summary.avg_variance AS variance_summary.avg_variance,
    variance_summary.critical_count AS variance_summary.critical_count,
    variance_summary.high_count AS variance_summary.high_count,
    variance_summary.medium_count AS variance_summary.medium_count,
    variance_summary.low_count AS variance_summary.low_count,
    variance_summary.severe_variance_count AS variance_summary.severe_variance_count
)

DIMENSIONS(
    entities.entity_id AS entities.entity_id
        WITH SYNONYMS ('org id', 'organization id', 'company id')
        COMMENT = 'Unique entity identifier',
    entities.entity_code AS entities.entity_code
        WITH SYNONYMS ('org code', 'company code')
        COMMENT = 'Business code for the entity',
    entities.entity_name AS entities.entity_name
        WITH SYNONYMS ('organization name', 'company name', 'org name')
        COMMENT = 'Display name of the entity',
    entities.entity_description AS entities.entity_description
        COMMENT = 'Detailed description',
    entities.entity_type AS entities.entity_type
        WITH SYNONYMS ('org type', 'type')
        COMMENT = 'Type classification',
    entities.parent_name AS entities.parent_name
        WITH SYNONYMS ('parent entity', 'parent org')
        COMMENT = 'Parent entity name',
    entities.entity_health_status AS entities.entity_health_status
        WITH SYNONYMS ('health status', 'status', 'health', 'risk status')
        COMMENT = 'Overall health (Critical, At Risk, Healthy, Needs Attention, No Activity)',
    entities.has_children AS entities.has_children
        COMMENT = 'Whether entity has child entities',
    entities.financial_review_required AS entities.financial_review_required
        WITH SYNONYMS ('requires review', 'needs review')
        COMMENT = 'Whether financial review is required',
    entities.hierarchy_lineage AS entities.hierarchy_lineage
        COMMENT = 'Hierarchy path lineage',
    variance_summary.period_id AS variance_summary.period_id
        COMMENT = 'Period identifier',
    variance_summary.period_year AS variance_summary.period_year
        WITH SYNONYMS ('year', 'fiscal year')
        COMMENT = 'Year of the period',
    variance_summary.period_quarter AS variance_summary.period_quarter
        WITH SYNONYMS ('quarter', 'fiscal quarter')
        COMMENT = 'Quarter of the period (1-4)',
    variance_summary.period_risk_level AS variance_summary.period_risk_level
        WITH SYNONYMS ('risk level', 'period risk')
        COMMENT = 'Risk classification (Critical, High Risk, Medium Risk, Low Risk)',
    variance_summary.period_end_date AS variance_summary.period_end_date
        WITH SYNONYMS ('period date', 'close date')
        COMMENT = 'End date of reconciliation period',
    entities.last_activity_date AS entities.last_activity_date
        WITH SYNONYMS ('last updated', 'last activity')
        COMMENT = 'Date of most recent activity'
)

METRICS(
    entities.total_entity_count AS COUNT(entities.entity_id)
        WITH SYNONYMS ('entity count', 'number of entities', 'org count')
        COMMENT = 'Total count of entities',
    entities.sum_gl_balance AS SUM(entities.total_gl_balance)
        WITH SYNONYMS ('total gl', 'aggregate gl balance')
        COMMENT = 'Sum of GL balances across entities',
    entities.sum_bank_balance AS SUM(entities.total_bank_balance)
        WITH SYNONYMS ('total bank', 'aggregate bank balance')
        COMMENT = 'Sum of bank balances across entities',
    entities.sum_variance AS SUM(entities.total_variance_amount)
        WITH SYNONYMS ('total variance', 'aggregate variance')
        COMMENT = 'Sum of variance amounts',
    entities.avg_completion_rate AS AVG(entities.reconciliation_completion_pct)
        WITH SYNONYMS ('average completion', 'mean completion rate')
        COMMENT = 'Average reconciliation completion percentage',
    entities.total_critical_variances AS SUM(entities.critical_variance_count)
        WITH SYNONYMS ('critical count', 'total critical issues')
        COMMENT = 'Total critical variances across entities',
    entities.entities_at_risk_count AS COUNT(CASE WHEN entities.entity_health_status IN ('Critical', 'At Risk') THEN 1 END)
        WITH SYNONYMS ('at risk count', 'risky entities')
        COMMENT = 'Entities with Critical or At Risk status',
    entities.healthy_entity_count AS COUNT(CASE WHEN entities.entity_health_status = 'Healthy' THEN 1 END)
        WITH SYNONYMS ('healthy count')
        COMMENT = 'Entities with Healthy status',
    variance_summary.sum_period_variance AS SUM(variance_summary.total_variance)
        COMMENT = 'Sum of variances across all periods',
    variance_summary.sum_period_critical AS SUM(variance_summary.critical_count)
        COMMENT = 'Total critical variances across periods'
)

COMMENT = 'Entity 360 semantic view for reconciliation management - enables natural language queries about entity health, reconciliation status, and variance analysis'