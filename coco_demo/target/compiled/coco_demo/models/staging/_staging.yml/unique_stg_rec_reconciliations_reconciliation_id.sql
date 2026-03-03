
    
    

select
    reconciliation_id as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT_STAGING.stg_rec_reconciliations
where reconciliation_id is not null
group by reconciliation_id
having count(*) > 1


