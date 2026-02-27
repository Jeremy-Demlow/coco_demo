select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select reconciliation_id
from DBAPI_REPLICA_DB.PUBLIC_MARTS.reconciliation_fact
where reconciliation_id is null



      
    ) dbt_internal_test