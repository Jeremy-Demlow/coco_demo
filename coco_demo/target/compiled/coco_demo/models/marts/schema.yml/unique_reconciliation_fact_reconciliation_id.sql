
    
    

select
    reconciliation_id as unique_field,
    count(*) as n_records

from DBAPI_REPLICA_DB.PUBLIC_MARTS.reconciliation_fact
where reconciliation_id is not null
group by reconciliation_id
having count(*) > 1


