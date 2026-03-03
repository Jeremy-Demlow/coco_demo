
    
    

select
    period_id as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT.dim_period
where period_id is not null
group by period_id
having count(*) > 1


