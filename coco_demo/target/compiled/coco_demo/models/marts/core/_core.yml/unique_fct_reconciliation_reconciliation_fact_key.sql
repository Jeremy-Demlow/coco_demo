
    
    

select
    reconciliation_fact_key as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT.fct_reconciliation
where reconciliation_fact_key is not null
group by reconciliation_fact_key
having count(*) > 1


