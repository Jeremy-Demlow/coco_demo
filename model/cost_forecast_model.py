"""
Train a cost forecasting model using Snowflake ML.
Predicts daily cloud costs using time-series features.
"""

from snowpark_session import create_snowpark_session
from snowflake.ml.modeling.xgboost import XGBRegressor
from snowflake.ml.registry import Registry
import snowflake.snowpark.functions as F
import pandas as pd
import numpy as np

def create_features(session):
    """Create feature-engineered dataset for cost forecasting."""
    
    # Aggregate daily costs by service
    daily_costs = session.table("BILLING_DATA").group_by(
        "BILLING_DATE", "CLOUD_PROVIDER", "SERVICE", "DEPARTMENT"
    ).agg(
        F.sum("COST").alias("DAILY_COST"),
        F.sum("USAGE_QUANTITY").alias("DAILY_USAGE")
    )
    
    # Add time-based features
    features_df = daily_costs.with_column(
        "DAY_OF_WEEK", F.dayofweek("BILLING_DATE")
    ).with_column(
        "DAY_OF_MONTH", F.dayofmonth("BILLING_DATE")
    ).with_column(
        "MONTH", F.month("BILLING_DATE")
    ).with_column(
        "QUARTER", F.quarter("BILLING_DATE")
    ).with_column(
        "IS_WEEKEND", F.when(F.dayofweek("BILLING_DATE") >= 5, 1).otherwise(0)
    ).with_column(
        "IS_END_OF_MONTH", F.when(F.dayofmonth("BILLING_DATE") >= 28, 1).otherwise(0)
    )
    
    return features_df

def train_model(session):
    """Train the cost forecasting model."""
    
    print("\n" + "="*60)
    print("COST FORECASTING MODEL TRAINING")
    print("="*60)
    
    # Create features
    print("Creating features...")
    features_df = create_features(session)
    
    # Convert to pandas
    pdf = features_df.to_pandas()
    
    print(f"Dataset shape: {pdf.shape}")
    print(f"Date range: {pdf['BILLING_DATE'].min()} to {pdf['BILLING_DATE'].max()}")
    print(f"Total records: {len(pdf):,}")
    
    # Encode categorical columns with label encoding
    from sklearn.preprocessing import LabelEncoder
    
    le_provider = LabelEncoder()
    le_service = LabelEncoder()
    le_dept = LabelEncoder()
    
    pdf['PROVIDER_ENCODED'] = le_provider.fit_transform(pdf['CLOUD_PROVIDER'])
    pdf['SERVICE_ENCODED'] = le_service.fit_transform(pdf['SERVICE'])
    pdf['DEPT_ENCODED'] = le_dept.fit_transform(pdf['DEPARTMENT'])
    
    # Split: use last 30 days for test
    pdf['BILLING_DATE'] = pd.to_datetime(pdf['BILLING_DATE'])
    cutoff_date = pdf['BILLING_DATE'].max() - pd.Timedelta(days=30)
    
    train_df = pdf[pdf['BILLING_DATE'] < cutoff_date].copy()
    test_df = pdf[pdf['BILLING_DATE'] >= cutoff_date].copy()
    
    print(f"\nTrain set: {len(train_df):,} records")
    print(f"Test set: {len(test_df):,} records")
    
    # Define features
    feature_cols = ['PROVIDER_ENCODED', 'SERVICE_ENCODED', 'DEPT_ENCODED',
                    'DAY_OF_WEEK', 'DAY_OF_MONTH', 'MONTH', 'QUARTER', 
                    'IS_WEEKEND', 'IS_END_OF_MONTH', 'DAILY_USAGE']
    target_col = 'DAILY_COST'
    
    # Convert to Snowpark DataFrames (only needed columns)
    train_cols = feature_cols + [target_col]
    train_sp = session.create_dataframe(train_df[train_cols].reset_index(drop=True))
    test_sp = session.create_dataframe(test_df[train_cols].reset_index(drop=True))
    
    # Create XGBRegressor
    print("\nTraining XGBoost model...")
    model = XGBRegressor(
        input_cols=feature_cols,
        label_cols=[target_col],
        output_cols=["PREDICTED_COST"],
        n_estimators=100,
        max_depth=6,
        learning_rate=0.1,
        random_state=42
    )
    
    # Train the model
    model.fit(train_sp)
    
    # Make predictions on test set
    print("Evaluating on test set...")
    predictions_sp = model.predict(test_sp)
    predictions_df = predictions_sp.to_pandas()
    
    # Calculate metrics
    y_true = predictions_df[target_col]
    y_pred = predictions_df['PREDICTED_COST']
    
    mae = np.mean(np.abs(y_true - y_pred))
    rmse = np.sqrt(np.mean((y_true - y_pred) ** 2))
    mape = np.mean(np.abs((y_true - y_pred) / y_true)) * 100
    r2 = 1 - np.sum((y_true - y_pred) ** 2) / np.sum((y_true - np.mean(y_true)) ** 2)
    
    print(f"\n{'='*40}")
    print("MODEL PERFORMANCE METRICS")
    print(f"{'='*40}")
    print(f"MAE:  ${mae:,.2f}")
    print(f"RMSE: ${rmse:,.2f}")
    print(f"MAPE: {mape:.2f}%")
    print(f"R²:   {r2:.3f}")
    
    # Store encoders for inference
    encoders = {
        'provider': le_provider,
        'service': le_service,
        'department': le_dept
    }
    
    return model, {"mae": mae, "rmse": rmse, "mape": mape, "r2": r2}, encoders

def register_model(session, model):
    """Register the trained model to Snowflake Model Registry."""
    
    print("\n" + "="*60)
    print("REGISTERING MODEL TO SNOWFLAKE")
    print("="*60)
    
    # Get or create registry
    registry = Registry(session=session, database_name="WORKSHOP_DB", schema_name="DEMO")
    
    # Register the model
    model_name = "COST_FORECASTING_MODEL"
    
    print(f"Registering model: {model_name}")
    model_version = registry.log_model(
        model=model,
        model_name=model_name,
        version_name=None,  # Auto-generate version
        comment="XGBoost cost forecasting model with time-series features",
        conda_dependencies=["snowflake-ml-python"]
    )
    
    print(f"Model registered: {model_name}")
    print(f"Version: {model_version.version_name}")
    
    # List all versions
    print("\nModel versions in registry:")
    model_ref = registry.get_model(model_name)
    for v in model_ref.versions():
        print(f"  - {v.version_name}")
    
    return model_version

def main():
    """Main training pipeline."""
    
    # Get Snowflake session
    session = create_snowpark_session()
    print(f"Connected to Snowflake: {session.get_current_account()}")
    
    # Set context
    session.sql("USE DATABASE WORKSHOP_DB").collect()
    session.sql("USE SCHEMA DEMO").collect()
    session.sql("USE WAREHOUSE WORKSHOP_WH").collect()
    
    # Train model
    model, metrics, encoders = train_model(session)
    
    # Register model
    model_version = register_model(session, model)
    
    print("\n" + "="*60)
    print("TRAINING COMPLETE")
    print("="*60)
    print(f"Model: WORKSHOP_DB.DEMO.COST_FORECASTING_MODEL")
    print(f"Version: {model_version.version_name}")
    print(f"MAE: ${metrics['mae']:,.2f}")
    print(f"MAPE: {metrics['mape']:.2f}%")
    
    session.close()

if __name__ == "__main__":
    main()
