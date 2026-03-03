
    
    

with all_values as (

    select
        reconciliation_status as value_field,
        count(*) as n_records

    from COCO_LIVE_DB.DBT.fct_reconciliation
    group by reconciliation_status

)

select *
from all_values
where value_field not in (
    'Fully Reconciled','Minor Variance','Moderate Variance','High Variance','Inactive'
)


