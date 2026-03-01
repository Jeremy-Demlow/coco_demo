select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select entity_id
from COCO_LIVE_DB.PUBLIC.mart_entity_360
where entity_id is null



      
    ) dbt_internal_test