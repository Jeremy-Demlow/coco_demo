



select
    1
from COCO_LIVE_DB.DBT.period_reconciliation_summary

where not(variance_alert_rate_pct >= 0 AND variance_alert_rate_pct <= 100)

