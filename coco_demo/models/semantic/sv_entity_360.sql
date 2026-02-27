{{
    config(
        materialized='semantic_view'
    )
}}

TABLES (
    entity_360 AS {{ ref('entity_360') }}
        PRIMARY KEY (entity_id, period_id)
        COMMENT = 'Entity-level 360 view with reconciliation metrics per period'
)

FACTS (
    entity_360.total_assignments AS total_assignments COMMENT = 'Total reconciliation assignments',
    entity_360.active_assignments AS active_assignments COMMENT = 'Number of active assignments',
    entity_360.assignments_with_activity AS assignments_with_activity COMMENT = 'Assignments with activity in period',
    entity_360.key_account_count AS key_account_count COMMENT = 'Number of key accounts',
    entity_360.total_gl_balance AS total_gl_balance COMMENT = 'Total GL balance in local currency',
    entity_360.total_gl_balance_base AS total_gl_balance_base COMMENT = 'Total GL balance in base currency',
    entity_360.total_bank_balance AS total_bank_balance COMMENT = 'Total bank balance',
    entity_360.total_bank_balance_base AS total_bank_balance_base COMMENT = 'Total bank balance in base currency',
    entity_360.total_subledger_balance AS total_subledger_balance COMMENT = 'Total subledger balance',
    entity_360.total_variance AS total_variance COMMENT = 'Total variance for the period',
    entity_360.total_absolute_variance AS total_absolute_variance COMMENT = 'Sum of absolute variances',
    entity_360.variance_count AS variance_count COMMENT = 'Count of variance records',
    entity_360.over_variance_count AS over_variance_count COMMENT = 'Count of over variances',
    entity_360.under_variance_count AS under_variance_count COMMENT = 'Count of under variances',
    entity_360.max_single_variance AS max_single_variance COMMENT = 'Largest single variance',
    entity_360.active_assignment_pct AS active_assignment_pct COMMENT = 'Percentage of active assignments',
    entity_360.activity_coverage_pct AS activity_coverage_pct COMMENT = 'Percentage with activity'
)

DIMENSIONS (
    entity_360.entity_id AS entity_id WITH SYNONYMS = ('organization id', 'org id') COMMENT = 'Unique entity identifier',
    entity_360.entity_code AS entity_code WITH SYNONYMS = ('org code', 'company code') COMMENT = 'Business code for the entity',
    entity_360.entity_name AS entity_name WITH SYNONYMS = ('organization name', 'company name') COMMENT = 'Display name of the entity',
    entity_360.period_id AS period_id COMMENT = 'Reconciliation period identifier',
    entity_360.period_year AS period_year WITH SYNONYMS = ('year', 'fiscal year') COMMENT = 'Year of the reconciliation period',
    entity_360.period_quarter AS period_quarter WITH SYNONYMS = ('quarter') COMMENT = 'Quarter of the reconciliation period',
    entity_360.period_month_num AS period_month_num WITH SYNONYMS = ('month') COMMENT = 'Month number of the period',
    entity_360.period_end_date AS period_end_date WITH SYNONYMS = ('period date', 'close date') COMMENT = 'End date of the reconciliation period',
    entity_360.variance_risk_level AS variance_risk_level WITH SYNONYMS = ('risk level', 'risk category') COMMENT = 'Risk classification based on variance'
)

METRICS (
    entity_360.total_entities AS COUNT(DISTINCT entity_id) WITH SYNONYMS = ('entity count') COMMENT = 'Count of distinct entities',
    entity_360.sum_gl_balance AS SUM(total_gl_balance) WITH SYNONYMS = ('aggregate gl balance') COMMENT = 'Sum of all GL balances',
    entity_360.sum_bank_balance AS SUM(total_bank_balance) COMMENT = 'Sum of all bank balances',
    entity_360.sum_variance AS SUM(total_variance) COMMENT = 'Sum of all variances',
    entity_360.sum_absolute_variance AS SUM(total_absolute_variance) COMMENT = 'Sum of absolute variances',
    entity_360.avg_gl_balance AS AVG(total_gl_balance) COMMENT = 'Average GL balance per entity',
    entity_360.high_risk_entity_count AS SUM(CASE WHEN variance_risk_level = 'High Risk' THEN 1 ELSE 0 END) WITH SYNONYMS = ('risky entities') COMMENT = 'Count of high risk entities'
)

COMMENT = 'Semantic view for entity-level reconciliation 360 analysis'
