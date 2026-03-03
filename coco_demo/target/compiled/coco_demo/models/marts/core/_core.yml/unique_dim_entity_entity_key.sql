
    
    

select
    entity_key as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT.dim_entity
where entity_key is not null
group by entity_key
having count(*) > 1


