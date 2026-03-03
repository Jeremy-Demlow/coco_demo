



select
    1
from COCO_LIVE_DB.DBT.reconciliation_360

where not(gl_subledger_difference >= 0)

