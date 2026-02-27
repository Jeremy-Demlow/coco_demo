
TABLES(
    entity_360 AS COCO_LIVE_DB.DBT_MARTS.entity_360
        PRIMARY KEY (entity_id, period_id)
        WITH SYNONYMS = ('entities', 'organizations')
        COMMENT = 'Entity-level 360 view with aggregated reconciliation metrics by period'
)
FACTS(
    entity_360.total_assignments AS total_assignments
        WITH SYNONYMS = ('assignment count', 'number of assignments')
        COMMENT = 'Total number of reconciliation assignments for the entity',
    entity_360.active_assignments AS active_assignments
        WITH SYNONYMS = ('active count', 'in-progress assignments')
        COMMENT = 'Number of currently active assignments',
    entity_360.total_balance_gl AS total_balance_gl
        WITH SYNONYMS = ('gl balance', 'general ledger balance')
        COMMENT = 'Total general ledger balance',
    entity_360.total_balance_bank AS total_balance_bank
        WITH SYNONYMS = ('bank balance', 'cash balance')
        COMMENT = 'Total bank balance',
    entity_360.total_variance AS total_variance
        WITH SYNONYMS = ('variance amount')
        COMMENT = 'Total absolute variance amount',
    entity_360.total_reconciliations AS total_reconciliations
        WITH SYNONYMS = ('reconciliation count', 'number of reconciliations')
        COMMENT = 'Total number of reconciliation records',
    entity_360.total_unreconciled_amount AS total_unreconciled_amount
        WITH SYNONYMS = ('unreconciled balance', 'outstanding amount')
        COMMENT = 'Total amount remaining unreconciled',
    entity_360.assignment_completion_rate AS assignment_completion_rate
        WITH SYNONYMS = ('completion percentage', 'completion rate')
        COMMENT = 'Percentage of assignments completed',
    entity_360.ownership_percentage AS ownership_percentage
        WITH SYNONYMS = ('ownership', 'ownership pct')
        COMMENT = 'Ownership percentage of the entity'
)
DIMENSIONS(
    entity_360.entity_id AS entity_id
        WITH SYNONYMS = ('entity identifier', 'org id')
        COMMENT = 'Unique identifier for the organization entity',
    entity_360.entity_code AS entity_code
        WITH SYNONYMS = ('entity number', 'org code')
        COMMENT = 'Business code for the entity',
    entity_360.entity_name AS entity_name
        WITH SYNONYMS = ('organization name', 'company name', 'entity')
        COMMENT = 'Name of the organization entity',
    entity_360.entity_type AS entity_type
        WITH SYNONYMS = ('organization type', 'entity category')
        COMMENT = 'Type classification of the entity',
    entity_360.parent_name AS parent_name
        WITH SYNONYMS = ('parent entity', 'parent organization')
        COMMENT = 'Name of the parent entity in the hierarchy',
    entity_360.hierarchy_depth AS hierarchy_depth
        WITH SYNONYMS = ('org level', 'hierarchy level')
        COMMENT = 'Depth level in the organization hierarchy',
    entity_360.variance_risk_level AS variance_risk_level
        WITH SYNONYMS = ('risk level', 'variance risk', 'risk category')
        COMMENT = 'Risk classification based on variance amount (High/Medium/Low)',
    entity_360.period_end_date AS period_end_date
        WITH SYNONYMS = ('period date', 'close date', 'reconciliation date')
        COMMENT = 'End date of the reconciliation period',
    entity_360.period_year AS period_year
        WITH SYNONYMS = ('year', 'fiscal year')
        COMMENT = 'Year of the reconciliation period',
    entity_360.period_quarter AS period_quarter
        WITH SYNONYMS = ('quarter', 'fiscal quarter')
        COMMENT = 'Quarter of the reconciliation period (1-4)',
    entity_360.period_month_num AS period_month_num
        WITH SYNONYMS = ('month', 'period month')
        COMMENT = 'Month number of the reconciliation period (1-12)'
)
METRICS(
    entity_360.sum_total_variance AS SUM(entity_360.total_variance)
        WITH SYNONYMS = ('aggregate variance', 'total variance sum')
        COMMENT = 'Sum of all variance amounts',
    entity_360.sum_unreconciled AS SUM(entity_360.total_unreconciled_amount)
        WITH SYNONYMS = ('total unreconciled', 'aggregate unreconciled')
        COMMENT = 'Sum of all unreconciled amounts',
    entity_360.avg_completion_rate AS AVG(entity_360.assignment_completion_rate)
        WITH SYNONYMS = ('average completion', 'mean completion rate')
        COMMENT = 'Average assignment completion rate',
    entity_360.count_entities AS COUNT(DISTINCT entity_360.entity_id)
        WITH SYNONYMS = ('entity count', 'number of entities')
        COMMENT = 'Count of distinct entities',
    entity_360.count_high_risk_entities AS COUNT(CASE WHEN entity_360.variance_risk_level = 'High' THEN 1 END)
        WITH SYNONYMS = ('high risk count', 'risky entities')
        COMMENT = 'Count of entities with high variance risk',
    entity_360.sum_gl_balance AS SUM(entity_360.total_balance_gl)
        WITH SYNONYMS = ('total gl', 'aggregate gl balance')
        COMMENT = 'Sum of general ledger balances',
    entity_360.sum_bank_balance AS SUM(entity_360.total_balance_bank)
        WITH SYNONYMS = ('total bank', 'aggregate bank balance')
        COMMENT = 'Sum of bank balances'
)
COMMENT = 'Comprehensive entity-level 360 view for financial reconciliation analysis'