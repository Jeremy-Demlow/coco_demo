-- ============================================================
-- 07_create_prediction_procedure.sql
-- Creates stored procedure for ML fraud prediction
-- 
-- Prerequisites:
-- - FRAUD_DETECTION_MODEL must exist in WORKSHOP_DB.DEMO
-- - Model trained via model/fraud_model.py
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA DEMO;

-- First create a UDF wrapper for the model 
-- (model functions can't be called directly inside procedures without this)
CREATE OR REPLACE FUNCTION PREDICT_FRAUD_UDF(
    AMOUNT FLOAT, 
    TRANSACTION_TYPE VARCHAR, 
    CHANNEL VARCHAR, 
    LOCATION VARCHAR, 
    MERCHANT VARCHAR
)
RETURNS INT
AS
$$
    WORKSHOP_DB.DEMO.FRAUD_DETECTION_MODEL!PREDICT(AMOUNT, TRANSACTION_TYPE, CHANNEL, LOCATION, MERCHANT):IS_FRAUD::INT
$$;

-- Create stored procedure that uses the UDF
-- EXECUTE AS CALLER is required for the UDF to resolve the model correctly
CREATE OR REPLACE PROCEDURE PREDICT_FRAUD(P_TRANSACTION_ID VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Predicts fraud risk for a transaction using the FRAUD_DETECTION_MODEL'
EXECUTE AS CALLER
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
        'predicted_fraud', WORKSHOP_DB.DEMO.PREDICT_FRAUD_UDF(t.AMOUNT, t.TRANSACTION_TYPE, t.CHANNEL, t.LOCATION, t.MERCHANT) = 1,
        'actual_fraud', t.IS_FRAUD,
        'risk_assessment', CASE 
            WHEN WORKSHOP_DB.DEMO.PREDICT_FRAUD_UDF(t.AMOUNT, t.TRANSACTION_TYPE, t.CHANNEL, t.LOCATION, t.MERCHANT) = 1 THEN 'HIGH RISK - Model predicts fraud'
            WHEN t.AMOUNT > 5000 THEN 'ELEVATED - High value transaction'
            WHEN t.CHANNEL = 'Online' AND t.TRANSACTION_TYPE = 'Wire' THEN 'ELEVATED - Online wire transfer'
            ELSE 'NORMAL - No fraud indicators detected'
        END
    ) INTO :result
    FROM WORKSHOP_DB.DEMO.TRANSACTIONS t
    WHERE t.TRANSACTION_ID = :P_TRANSACTION_ID;
    
    RETURN result;
END;
$$;

-- Test the procedure
CALL PREDICT_FRAUD('TXN_0000001');

-- Show procedures
SHOW PROCEDURES LIKE 'PREDICT_FRAUD' IN SCHEMA WORKSHOP_DB.DEMO;
