
    
    

select
    assignment_key as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT.dim_assignment
where assignment_key is not null
group by assignment_key
having count(*) > 1


