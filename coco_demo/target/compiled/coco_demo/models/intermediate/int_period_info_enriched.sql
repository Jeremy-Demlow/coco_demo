

WITH period_info_enriched AS (
    SELECT
        pi.period_info_id,
        pi.assignment_id,
        pi.period_id,
        pi.consolidation_id,
        pi.financial_statement_id,
        
        pi.is_active,
        pi.has_activity,
        pi.is_key_account,
        pi.purpose,
        pi.reconciliation_procedure,
        pi.recon_frequency,
        
        pi.balance_gl,
        pi.balance_gl_base,
        pi.balance_gl_func,
        pi.balance_bank,
        pi.balance_bank_base,
        pi.balance_bank_func,
        pi.balance_subledger,
        pi.balance_subledger_base,
        pi.balance_subledger_func,
        pi.balance_estimate,
        pi.balance_estimate_base,
        pi.balance_estimate_func,
        pi.balance_forecast,
        pi.balance_forecast_base,
        pi.balance_forecast_func,
        
        ABS(COALESCE(pi.balance_gl, 0) - COALESCE(pi.balance_bank, 0)) AS gl_bank_difference,
        ABS(COALESCE(pi.balance_gl, 0) - COALESCE(pi.balance_subledger, 0)) AS gl_subledger_difference,
        ABS(COALESCE(pi.balance_gl, 0) - COALESCE(pi.balance_estimate, 0)) AS gl_estimate_difference,
        
        CASE 
            WHEN pi.balance_gl IS NOT NULL AND pi.balance_gl != 0 
            THEN ABS(COALESCE(pi.balance_gl, 0) - COALESCE(pi.balance_bank, 0)) / ABS(pi.balance_gl) * 100
            ELSE 0
        END AS gl_bank_variance_pct,
        
        p.period_end_date,
        p.period_month,
        p.period_year,
        p.period_quarter,
        p.period_month_name,
        
        pi.account_balance_last_update_date,
        pi.last_update_date,
        pi.created_at,
        pi.updated_at
        
    FROM COCO_LIVE_DB.DBT_STAGING.stg_rec_period_information pi
    INNER JOIN COCO_LIVE_DB.DBT_STAGING.stg_rec_periods p
        ON pi.period_id = p.period_id
)

SELECT * FROM period_info_enriched