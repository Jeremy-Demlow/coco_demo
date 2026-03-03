



select
    1
from COCO_LIVE_DB.DBT.period_reconciliation_summary

where not(completion_rate_pct >= 0 AND completion_rate_pct <= 100)

