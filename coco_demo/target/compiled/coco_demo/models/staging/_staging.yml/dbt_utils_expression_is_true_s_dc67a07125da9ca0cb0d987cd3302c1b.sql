



select
    1
from COCO_LIVE_DB.DBT_STAGING.stg_rec_reconciliations

where not(amount_unidentified >= 0)

