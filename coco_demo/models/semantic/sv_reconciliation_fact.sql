{{
    config(
        materialized='semantic_view'
    )
}}

TABLES (
    reconciliation_fact AS {{ ref('reconciliation_fact') }}
        PRIMARY KEY (reconciliation_id)
        COMMENT = 'Detailed reconciliation records with balance comparisons'
)

FACTS (
    reconciliation_fact.balance_bank AS balance_bank COMMENT = 'Bank balance in local currency',
    reconciliation_fact.balance_bank_base AS balance_bank_base COMMENT = 'Bank balance in base currency',
    reconciliation_fact.balance_calculated AS balance_calculated COMMENT = 'Calculated balance',
    reconciliation_fact.balance_calculated_base AS balance_calculated_base COMMENT = 'Calculated balance in base currency',
    reconciliation_fact.balance_subledger AS balance_subledger COMMENT = 'Subledger balance',
    reconciliation_fact.balance_subledger_base AS balance_subledger_base COMMENT = 'Subledger balance in base currency',
    reconciliation_fact.amount_unidentified AS amount_unidentified COMMENT = 'Unidentified amount',
    reconciliation_fact.bank_calc_diff AS bank_calc_diff COMMENT = 'Bank vs calculated difference',
    reconciliation_fact.bank_subledger_diff AS bank_subledger_diff COMMENT = 'Bank vs subledger difference'
)

DIMENSIONS (
    reconciliation_fact.reconciliation_id AS reconciliation_id COMMENT = 'Unique reconciliation identifier',
    reconciliation_fact.assignment_id AS assignment_id COMMENT = 'Assignment identifier',
    reconciliation_fact.entity_id AS entity_id WITH SYNONYMS = ('organization id', 'company id') COMMENT = 'Organization entity identifier',
    reconciliation_fact.entity_code AS entity_code WITH SYNONYMS = ('org code') COMMENT = 'Business code for entity',
    reconciliation_fact.entity_name AS entity_name WITH SYNONYMS = ('organization name', 'company name') COMMENT = 'Display name of entity',
    reconciliation_fact.entity_parent_name AS entity_parent_name WITH SYNONYMS = ('parent organization') COMMENT = 'Parent entity name',
    reconciliation_fact.assignment_key AS assignment_key COMMENT = 'Business key for assignment',
    reconciliation_fact.assignment_type AS assignment_type COMMENT = 'Type of assignment',
    reconciliation_fact.account_combination AS account_combination WITH SYNONYMS = ('gl account', 'account combo') COMMENT = 'Account combination string',
    reconciliation_fact.currency AS currency COMMENT = 'Currency of reconciliation',
    reconciliation_fact.reconciliation_type AS reconciliation_type COMMENT = 'Type of reconciliation',
    reconciliation_fact.reconciliation_status AS reconciliation_status WITH SYNONYMS = ('status', 'recon status') COMMENT = 'Calculated status',
    reconciliation_fact.period_year AS period_year WITH SYNONYMS = ('year') COMMENT = 'Year of period',
    reconciliation_fact.period_quarter AS period_quarter WITH SYNONYMS = ('quarter') COMMENT = 'Quarter of period',
    reconciliation_fact.period_month_num AS period_month_num WITH SYNONYMS = ('month') COMMENT = 'Month number',
    reconciliation_fact.period_end_date AS period_end_date WITH SYNONYMS = ('period date', 'close date') COMMENT = 'Period end date',
    reconciliation_fact.segment1 AS segment1 COMMENT = 'Account segment 1',
    reconciliation_fact.segment2 AS segment2 COMMENT = 'Account segment 2',
    reconciliation_fact.segment3 AS segment3 COMMENT = 'Account segment 3'
)

METRICS (
    reconciliation_fact.total_reconciliations AS COUNT(*) WITH SYNONYMS = ('recon count') COMMENT = 'Total reconciliation count',
    reconciliation_fact.sum_bank_balance AS SUM(balance_bank) WITH SYNONYMS = ('total bank balance') COMMENT = 'Sum of bank balances',
    reconciliation_fact.sum_calculated_balance AS SUM(balance_calculated) COMMENT = 'Sum of calculated balances',
    reconciliation_fact.sum_unidentified AS SUM(amount_unidentified) COMMENT = 'Sum of unidentified amounts',
    reconciliation_fact.sum_bank_calc_diff AS SUM(bank_calc_diff) WITH SYNONYMS = ('total difference') COMMENT = 'Sum of differences',
    reconciliation_fact.reconciled_count AS SUM(CASE WHEN reconciliation_status = 'Reconciled' THEN 1 ELSE 0 END) COMMENT = 'Count of reconciled items',
    reconciliation_fact.needs_review_count AS SUM(CASE WHEN reconciliation_status = 'Needs Review' THEN 1 ELSE 0 END) WITH SYNONYMS = ('review needed') COMMENT = 'Items needing review',
    reconciliation_fact.reconciliation_rate AS SUM(CASE WHEN reconciliation_status = 'Reconciled' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) WITH SYNONYMS = ('completion rate') COMMENT = 'Percentage reconciled'
)

COMMENT = 'Semantic view for detailed reconciliation analysis'
