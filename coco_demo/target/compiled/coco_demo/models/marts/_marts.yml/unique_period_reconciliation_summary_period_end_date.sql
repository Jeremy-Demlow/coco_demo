
    
    

select
    period_end_date as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT.period_reconciliation_summary
where period_end_date is not null
group by period_end_date
having count(*) > 1


