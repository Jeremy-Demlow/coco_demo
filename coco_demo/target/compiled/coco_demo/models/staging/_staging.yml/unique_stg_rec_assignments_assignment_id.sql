
    
    

select
    assignment_id as unique_field,
    count(*) as n_records

from COCO_LIVE_DB.DBT_STAGING.stg_rec_assignments
where assignment_id is not null
group by assignment_id
having count(*) > 1


