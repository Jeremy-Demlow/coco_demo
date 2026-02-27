{{
    config(
        materialized='table',
        schema='MARTS'
    )
}}

with recon as (
    select * from {{ ref('stg_rec_reconciliations') }}
),

assignments as (
    select * from {{ ref('stg_rec_assignments') }}
),

entities as (
    select * from {{ ref('stg_org_entities') }}
),

periods as (
    select * from {{ ref('stg_rec_periods') }}
)

select
    r.reconciliation_id,
    r.assignment_id,
    r.period_id,
    a.entity_id,
    e.entity_code,
    e.entity_name,
    e.parent_name as entity_parent_name,
    e.hierarchy_depth,
    p.period_end_date,
    p.period_year,
    p.period_quarter,
    p.period_month_num,
    a.assignment_key,
    a.assignment_type,
    a.account_combination,
    a.currency,
    a.segment1, a.segment2, a.segment3, a.segment4, a.segment5,
    r.reconciliation_type,
    r.balance_bank,
    r.balance_bank_base,
    r.balance_bank_func,
    r.balance_calculated,
    r.balance_calculated_base,
    r.balance_calculated_func,
    r.balance_subledger,
    r.balance_subledger_base,
    r.balance_subledger_func,
    r.amount_unidentified,
    r.balance_bank - r.balance_calculated as bank_calc_diff,
    r.balance_bank - r.balance_subledger as bank_subledger_diff,
    case 
        when abs(r.balance_bank - r.balance_calculated) > 1000 then 'Needs Review'
        when abs(r.balance_bank - r.balance_calculated) > 0 then 'Minor Difference'
        else 'Reconciled'
    end as reconciliation_status,
    r.created_at,
    r.updated_at,
    current_timestamp() as dbt_updated_at
from recon r
left join assignments a on r.assignment_id = a.assignment_id
left join entities e on a.entity_id = e.entity_id
left join periods p on r.period_id = p.period_id
