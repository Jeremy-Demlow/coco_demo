create or replace semantic view COCO_LIVE_DB.DBT_MARTS.sv_assignment_360
  
TABLES(
    assignment_360 AS COCO_LIVE_DB.DBT_MARTS.assignment_360
        PRIMARY KEY (assignment_id, period_id)
        WITH SYNONYMS = ('assignments', 'reconciliations')
        COMMENT = 'Assignment-level 360 view with detailed reconciliation and variance data'
)
FACTS(
    assignment_360.balance_gl AS balance_gl
        WITH SYNONYMS = ('gl balance', 'general ledger')
        COMMENT = 'General ledger balance',
    assignment_360.balance_bank AS balance_bank
        WITH SYNONYMS = ('bank balance', 'cash balance')
        COMMENT = 'Bank balance',
    assignment_360.balance_subledger AS balance_subledger
        WITH SYNONYMS = ('subledger balance', 'subsidiary balance')
        COMMENT = 'Subledger balance',
    assignment_360.total_variance AS total_variance
        WITH SYNONYMS = ('variance', 'variance amount')
        COMMENT = 'Total variance amount',
    assignment_360.unreconciled_amount AS unreconciled_amount
        WITH SYNONYMS = ('unreconciled', 'outstanding balance')
        COMMENT = 'Unreconciled amount',
    assignment_360.reconciliation_count AS reconciliation_count
        WITH SYNONYMS = ('recon count', 'number of reconciliations')
        COMMENT = 'Count of reconciliation records'
)
DIMENSIONS(
    assignment_360.assignment_id AS assignment_id
        WITH SYNONYMS = ('assignment identifier', 'assignment number')
        COMMENT = 'Unique identifier for the reconciliation assignment',
    assignment_360.assignment_type AS assignment_type
        WITH SYNONYMS = ('type', 'assignment category')
        COMMENT = 'Type of assignment (Balance, Flux, Activity)',
    assignment_360.combo_name AS combo_name
        WITH SYNONYMS = ('combination name', 'account combo')
        COMMENT = 'Account combination name',
    assignment_360.currency AS currency
        WITH SYNONYMS = ('currency code', 'transaction currency')
        COMMENT = 'Currency of the assignment',
    assignment_360.segment1 AS segment1
        WITH SYNONYMS = ('segment 1', 'account segment 1')
        COMMENT = 'First account segment',
    assignment_360.segment2 AS segment2
        WITH SYNONYMS = ('segment 2', 'account segment 2')
        COMMENT = 'Second account segment',
    assignment_360.segment3 AS segment3
        WITH SYNONYMS = ('segment 3', 'account segment 3')
        COMMENT = 'Third account segment',
    assignment_360.entity_id AS entity_id
        WITH SYNONYMS = ('org id')
        COMMENT = 'Entity identifier',
    assignment_360.entity_name AS entity_name
        WITH SYNONYMS = ('organization', 'company')
        COMMENT = 'Name of the associated entity',
    assignment_360.entity_code AS entity_code
        WITH SYNONYMS = ('entity number', 'org code')
        COMMENT = 'Code of the associated entity',
    assignment_360.status AS status
        WITH SYNONYMS = ('assignment status', 'current status')
        COMMENT = 'Current status of the assignment (Active/Inactive)',
    assignment_360.variance_risk AS variance_risk
        WITH SYNONYMS = ('risk level', 'variance risk level')
        COMMENT = 'Variance risk classification (High/Medium/Low)',
    assignment_360.reconciliation_status AS reconciliation_status
        WITH SYNONYMS = ('recon status', 'reconciliation state')
        COMMENT = 'Current reconciliation status',
    assignment_360.period_end_date AS period_end_date
        WITH SYNONYMS = ('period date', 'close date')
        COMMENT = 'End date of the reconciliation period',
    assignment_360.period_year AS period_year
        WITH SYNONYMS = ('year', 'fiscal year')
        COMMENT = 'Year of the reconciliation period',
    assignment_360.period_quarter AS period_quarter
        WITH SYNONYMS = ('quarter', 'fiscal quarter')
        COMMENT = 'Quarter of the reconciliation period'
)
METRICS(
    assignment_360.sum_gl_balance AS SUM(assignment_360.balance_gl)
        WITH SYNONYMS = ('total gl', 'aggregate gl')
        COMMENT = 'Sum of GL balances',
    assignment_360.sum_bank_balance AS SUM(assignment_360.balance_bank)
        WITH SYNONYMS = ('total bank', 'aggregate bank')
        COMMENT = 'Sum of bank balances',
    assignment_360.sum_variance AS SUM(assignment_360.total_variance)
        WITH SYNONYMS = ('total variance', 'aggregate variance')
        COMMENT = 'Sum of variance amounts',
    assignment_360.sum_unreconciled AS SUM(assignment_360.unreconciled_amount)
        WITH SYNONYMS = ('total unreconciled', 'aggregate unreconciled')
        COMMENT = 'Sum of unreconciled amounts',
    assignment_360.count_assignments AS COUNT(DISTINCT assignment_360.assignment_id)
        WITH SYNONYMS = ('assignment count', 'total assignments')
        COMMENT = 'Count of assignments',
    assignment_360.count_high_risk AS COUNT(CASE WHEN assignment_360.variance_risk = 'High' THEN 1 END)
        WITH SYNONYMS = ('high risk count', 'risky assignments')
        COMMENT = 'Count of high variance risk assignments',
    assignment_360.count_needs_review AS COUNT(CASE WHEN assignment_360.reconciliation_status = 'Needs Review' THEN 1 END)
        WITH SYNONYMS = ('review count', 'needs attention')
        COMMENT = 'Count of assignments needing review',
    assignment_360.avg_variance AS AVG(assignment_360.total_variance)
        WITH SYNONYMS = ('average variance', 'mean variance')
        COMMENT = 'Average variance amount'
)
COMMENT = 'Comprehensive assignment-level 360 view for financial reconciliation analysis'