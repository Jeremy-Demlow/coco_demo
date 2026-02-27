select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select entity_id
from DBAPI_REPLICA_DB.PUBLIC_MARTS.entity_360
where entity_id is null



      
    ) dbt_internal_test