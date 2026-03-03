
    
    

select
    period_info_id as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT_INTERMEDIATE.int_period_info_enriched
where period_info_id is not null
group by period_info_id
having count(*) > 1


