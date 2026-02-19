-- ============================================================
-- 07_create_prediction_procedure.sql
-- Creates stored procedure for ML fraud prediction
-- 
-- Prerequisites:
-- - FRAUD_DETECTION_MODEL must exist in WORKSHOP_DB.DEMO
-- - Model trained via notebooks/fraud_model.py
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- Create stored procedure that calls the ML model
CREATE OR REPLACE PROCEDURE PREDICT_FRAUD(TRANSACTION_ID VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Predicts fraud risk for a transaction using the FRAUD_DETECTION_MODEL'
AS
$$
DECLARE
    result VARIANT;
BEGIN
    SELECT OBJECT_CONSTRUCT(
        'transaction_id', t.TRANSACTION_ID,
        'amount', t.AMOUNT,
        'transaction_type', t.TRANSACTION_TYPE,
        'channel', t.CHANNEL,
        'merchant', t.MERCHANT,
        'location', t.LOCATION,
        'predicted_fraud', CASE 
            WHEN FRAUD_DETECTION_MODEL!PREDICT(
                t.AMOUNT, t.TRANSACTION_TYPE, t.CHANNEL, t.LOCATION, t.MERCHANT
            ):IS_FRAUD::INT = 1 THEN TRUE
            ELSE FALSE
        END,
        'actual_fraud', t.IS_FRAUD,
        'risk_assessment', CASE 
            WHEN FRAUD_DETECTION_MODEL!PREDICT(
                t.AMOUNT, t.TRANSACTION_TYPE, t.CHANNEL, t.LOCATION, t.MERCHANT
            ):IS_FRAUD::INT = 1 THEN 'HIGH RISK - Model predicts fraud'
            WHEN t.AMOUNT > 5000 THEN 'ELEVATED - High value transaction'
            WHEN t.CHANNEL = 'Online' AND t.TRANSACTION_TYPE = 'Wire' THEN 'ELEVATED - Online wire transfer'
            ELSE 'NORMAL - No fraud indicators detected'
        END
    ) INTO :result
    FROM TRANSACTIONS t
    WHERE t.TRANSACTION_ID = :TRANSACTION_ID;
    
    RETURN result;
END;
$$;

-- Test the procedure
CALL PREDICT_FRAUD('TXN_0000001');

-- Show procedures
SHOW PROCEDURES LIKE 'PREDICT_FRAUD' IN SCHEMA WORKSHOP_DB.DEMO;
