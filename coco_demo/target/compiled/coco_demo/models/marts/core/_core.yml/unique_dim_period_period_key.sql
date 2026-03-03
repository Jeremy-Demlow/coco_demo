
    
    

select
    period_key as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT.dim_period
where period_key is not null
group by period_key
having count(*) > 1


