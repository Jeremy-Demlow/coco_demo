
    
    

select
    entity_id as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT.dim_entity
where entity_id is not null
group by entity_id
having count(*) > 1


