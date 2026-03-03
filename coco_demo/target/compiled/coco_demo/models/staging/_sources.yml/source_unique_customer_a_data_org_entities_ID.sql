
    
    

select
    ID as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.CUSTOMER_A_DATA.org_entities
where ID is not null
group by ID
having count(*) > 1


