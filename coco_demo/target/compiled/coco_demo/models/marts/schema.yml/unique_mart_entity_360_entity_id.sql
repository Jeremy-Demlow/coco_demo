
    
    

select
    entity_id as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.PUBLIC.mart_entity_360
where entity_id is not null
group by entity_id
having count(*) > 1


