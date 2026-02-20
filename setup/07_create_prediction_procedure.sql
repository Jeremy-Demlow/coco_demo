-- ============================================================
-- 07_create_prediction_procedure.sql
-- Creates stored procedure for cost forecasting using Snowflake ML
-- 
-- Prerequisites: Run 08_create_ml_forecast_model.sql first
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- ============================================================
-- Procedure: FORECAST_COST (uses Snowflake ML FORECAST model)
-- Forecasts cost for a specific service and department
-- ============================================================
CREATE OR REPLACE PROCEDURE FORECAST_COST(
    TARGET_SERVICE VARCHAR,
    TARGET_DEPARTMENT VARCHAR,
    FORECAST_DAYS INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'forecast_cost'
AS
$$
from datetime import datetime

def forecast_cost(session, target_service, target_department, forecast_days):
    """Generate cost forecast using Snowflake ML FORECAST model."""
    
    # Get forecast from ML model (max 30 days, slice to requested)
    forecast_periods = min(forecast_days, 30)
    
    forecast_df = session.sql(f"""
        SELECT 
            SERIES AS SERVICE,
            TS::DATE AS FORECAST_DATE,
            ROUND(FORECAST, 2) AS DAILY_COST,
            ROUND(LOWER_BOUND, 2) AS LOWER_BOUND,
            ROUND(UPPER_BOUND, 2) AS UPPER_BOUND
        FROM TABLE(WORKSHOP_DB.DEMO.COST_FORECAST_MODEL!FORECAST(
            FORECASTING_PERIODS => 30
        ))
        WHERE SERIES = '{target_service}'
        ORDER BY TS
        LIMIT {forecast_periods}
    """).collect()
    
    if not forecast_df:
        return {
            "error": f"No forecast data for service: {target_service}",
            "service": target_service,
            "department": target_department
        }
    
    # Calculate aggregates
    daily_costs = [float(row['DAILY_COST']) for row in forecast_df]
    lower_bounds = [float(row['LOWER_BOUND']) for row in forecast_df]
    upper_bounds = [float(row['UPPER_BOUND']) for row in forecast_df]
    
    total_forecast = sum(daily_costs)
    avg_daily = total_forecast / len(daily_costs)
    
    return {
        "service": target_service,
        "department": target_department,
        "forecast_days": forecast_days,
        "forecasted_total": round(total_forecast, 2),
        "daily_average": round(avg_daily, 2),
        "confidence_interval": {
            "low": round(sum(lower_bounds), 2),
            "high": round(sum(upper_bounds), 2)
        },
        "model_type": "Snowflake ML FORECAST",
        "generated_at": datetime.now().isoformat(),
        "note": "95% confidence interval based on historical patterns"
    }
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
