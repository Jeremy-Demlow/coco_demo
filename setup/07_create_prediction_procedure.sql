-- ============================================================
-- 07_create_prediction_procedure.sql
-- Creates simple SQL-based cost forecasting procedure
-- 
-- This uses historical averages with a growth factor.
-- The user wanted simple, practical forecasting - not ML.FORECAST.
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create the forecast procedure
-- Parameters match the agent tool schema: TARGET_SERVICE, TARGET_DEPARTMENT, FORECAST_DAYS
CREATE OR REPLACE PROCEDURE FORECAST_COST(
    TARGET_SERVICE VARCHAR DEFAULT NULL,
    TARGET_DEPARTMENT VARCHAR DEFAULT NULL,
    FORECAST_DAYS INT DEFAULT 30
)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Simple SQL-based cost forecasting using historical averages'
AS
BEGIN
    LET result VARIANT;
    LET svc VARCHAR := TARGET_SERVICE;
    LET dept VARCHAR := TARGET_DEPARTMENT;
    LET days INT := FORECAST_DAYS;
    
    -- Simple forecast: historical avg × days × 1.05 growth factor
    result := (
        SELECT OBJECT_CONSTRUCT(
            'forecast_period_days', :days,
            'target_service', :svc,
            'target_department', :dept,
            'forecasted_total', ROUND(AVG(BILLED_COST) * :days * 1.05, 2),
            'confidence_interval', OBJECT_CONSTRUCT(
                'low', ROUND(AVG(BILLED_COST) * :days * 0.9, 2),
                'high', ROUND(AVG(BILLED_COST) * :days * 1.2, 2)
            ),
            'historical_stats', OBJECT_CONSTRUCT(
                'avg_daily_cost', ROUND(AVG(BILLED_COST), 2),
                'total_records', COUNT(*)
            ),
            'method', 'Historical average with 5% growth factor',
            'generated_at', CURRENT_TIMESTAMP()
        )
        FROM FOCUS_BILLING
        WHERE CHARGE_CATEGORY = 'Usage'
            AND (:svc IS NULL OR SERVICE_NAME ILIKE '%' || :svc || '%')
            AND (:dept IS NULL OR X_DEPARTMENT ILIKE '%' || :dept || '%')
    );
    
    RETURN result;
END;

-- Test
CALL FORECAST_COST('Compute', 'Engineering', 30);
