



select
    1
from COCO_LIVE_DB.DBT.entity_reconciliation_summary

where not(reconciliation_completion_rate >= 0 AND reconciliation_completion_rate <= 100)

