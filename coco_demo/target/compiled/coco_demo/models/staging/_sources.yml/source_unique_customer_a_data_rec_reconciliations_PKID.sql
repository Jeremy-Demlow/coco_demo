
    
    

select
    PKID as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.CUSTOMER_A_DATA.rec_reconciliations
where PKID is not null
group by PKID
having count(*) > 1


