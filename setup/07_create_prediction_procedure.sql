-- ============================================================
-- 07_create_prediction_procedure.sql
-- Creates stored procedure for cost forecasting
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Procedure: FORECAST_COST
-- Forecasts cost for a specific service/department combination
-- ============================================================
CREATE OR REPLACE PROCEDURE FORECAST_COST(
    TARGET_SERVICE VARCHAR,
    TARGET_DEPARTMENT VARCHAR,
    FORECAST_DAYS INT DEFAULT 30
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    result VARIANT;
BEGIN
    -- Get the latest available date and calculate forecast period
    LET latest_date DATE := (SELECT MAX(BILLING_DATE) FROM BILLING_DATA);
    
    -- Calculate historical averages for the service/department
    SELECT OBJECT_CONSTRUCT(
        'service', :TARGET_SERVICE,
        'department', :TARGET_DEPARTMENT,
        'forecast_days', :FORECAST_DAYS,
        'forecast_start', DATEADD('day', 1, :latest_date),
        'forecast_end', DATEADD('day', :FORECAST_DAYS, :latest_date),
        'historical_avg_daily_cost', ROUND(AVG(COST), 2),
        'historical_total_30d', ROUND(SUM(CASE WHEN BILLING_DATE > DATEADD('day', -30, :latest_date) THEN COST ELSE 0 END), 2),
        'forecasted_total', ROUND(AVG(COST) * :FORECAST_DAYS * 1.05, 2),  -- 5% growth factor
        'confidence_interval', OBJECT_CONSTRUCT(
            'low', ROUND(AVG(COST) * :FORECAST_DAYS * 0.9, 2),
            'high', ROUND(AVG(COST) * :FORECAST_DAYS * 1.2, 2)
        ),
        'trend', CASE 
            WHEN AVG(CASE WHEN BILLING_DATE > DATEADD('day', -7, :latest_date) THEN COST END) >
                 AVG(CASE WHEN BILLING_DATE <= DATEADD('day', -7, :latest_date) AND BILLING_DATE > DATEADD('day', -30, :latest_date) THEN COST END)
            THEN 'INCREASING'
            ELSE 'STABLE'
        END,
        'analysis', 'Forecast based on historical patterns with 5% growth adjustment. Consider seasonality and planned infrastructure changes.'
    ) INTO :result
    FROM BILLING_DATA
    WHERE SERVICE = :TARGET_SERVICE 
      AND DEPARTMENT = :TARGET_DEPARTMENT
      AND BILLING_DATE > DATEADD('day', -90, :latest_date);
    
    RETURN result;
END;
$$;

-- ============================================================
-- Procedure: FORECAST_TOTAL_COST
-- Forecasts total cost across all services
-- ============================================================
CREATE OR REPLACE PROCEDURE FORECAST_TOTAL_COST(
    FORECAST_DAYS INT DEFAULT 30
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    result VARIANT;
BEGIN
    LET latest_date DATE := (SELECT MAX(BILLING_DATE) FROM BILLING_DATA);
    
    SELECT OBJECT_CONSTRUCT(
        'forecast_period', OBJECT_CONSTRUCT(
            'start', DATEADD('day', 1, :latest_date),
            'end', DATEADD('day', :FORECAST_DAYS, :latest_date),
            'days', :FORECAST_DAYS
        ),
        'current_daily_average', ROUND(
            (SELECT AVG(daily_total) FROM (
                SELECT BILLING_DATE, SUM(COST) as daily_total 
                FROM BILLING_DATA 
                WHERE BILLING_DATE > DATEADD('day', -30, :latest_date)
                GROUP BY BILLING_DATE
            ))
        , 2),
        'forecasted_total', ROUND(
            (SELECT AVG(daily_total) * :FORECAST_DAYS * 1.03 FROM (
                SELECT BILLING_DATE, SUM(COST) as daily_total 
                FROM BILLING_DATA 
                WHERE BILLING_DATE > DATEADD('day', -30, :latest_date)
                GROUP BY BILLING_DATE
            ))
        , 2),
        'by_cloud_provider', (
            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
                'provider', CLOUD_PROVIDER,
                'forecasted_cost', ROUND(AVG(COST) * :FORECAST_DAYS * 1.03, 2)
            ))
            FROM BILLING_DATA
            WHERE BILLING_DATE > DATEADD('day', -30, :latest_date)
            GROUP BY CLOUD_PROVIDER
        ),
        'by_department', (
            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
                'department', DEPARTMENT,
                'forecasted_cost', ROUND(AVG(COST) * :FORECAST_DAYS * 1.03, 2)
            ))
            FROM BILLING_DATA
            WHERE BILLING_DATE > DATEADD('day', -30, :latest_date)
            GROUP BY DEPARTMENT
        )
    ) INTO :result
    FROM DUAL;
    
    RETURN result;
END;
$$;

-- Test the procedures
CALL FORECAST_COST('EC2', 'Engineering', 30);
CALL FORECAST_TOTAL_COST(30);
