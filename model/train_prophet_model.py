"""
Cost Forecasting Model - Prophet-based time series forecasting.
Trains and registers to Snowflake Model Registry.
"""

import sys
sys.path.insert(0, '/Users/jdemlow/Customers/Blackline/coco_demo/model')

from snowpark_session import create_snowpark_session
import pandas as pd
import numpy as np
from prophet import Prophet
import pickle
from pathlib import Path

def load_training_data(session):
    """Load and aggregate billing data for forecasting."""
    print("Loading billing data...")
    
    # Aggregate daily costs by service
    df = session.sql("""
        SELECT 
            BILLING_DATE as ds,
            SERVICE,
            SUM(COST) as y
        FROM WORKSHOP_DB.DEMO.BILLING_DATA
        GROUP BY BILLING_DATE, SERVICE
        ORDER BY BILLING_DATE
    """).to_pandas()
    
    # Convert date column
    df['ds'] = pd.to_datetime(df['DS'])
    df['y'] = df['Y'].astype(float)
    df['service'] = df['SERVICE']
    
    print(f"Loaded {len(df):,} rows")
    print(f"Date range: {df['ds'].min()} to {df['ds'].max()}")
    print(f"Services: {df['service'].nunique()}")
    
    return df[['ds', 'y', 'service']]

def train_prophet_model(df, service='EC2'):
    """Train a Prophet model for a specific service."""
    print(f"\nTraining Prophet model for {service}...")
    
    # Filter to specific service
    service_df = df[df['service'] == service][['ds', 'y']].copy()
    
    if len(service_df) == 0:
        raise ValueError(f"No data found for service: {service}")
    
    print(f"Training data: {len(service_df)} rows")
    
    # Initialize Prophet with sensible defaults for cost data
    model = Prophet(
        yearly_seasonality=True,
        weekly_seasonality=True,
        daily_seasonality=False,
        changepoint_prior_scale=0.05,
        seasonality_prior_scale=10,
    )
    
    # Fit model
    model.fit(service_df)
    
    # Generate forecast for validation
    future = model.make_future_dataframe(periods=30)
    forecast = model.predict(future)
    
    # Calculate metrics on training data
    train_forecast = forecast[forecast['ds'].isin(service_df['ds'])]
    merged = service_df.merge(train_forecast[['ds', 'yhat']], on='ds')
    
    mae = np.mean(np.abs(merged['y'] - merged['yhat']))
    rmse = np.sqrt(np.mean((merged['y'] - merged['yhat'])**2))
    mape = np.mean(np.abs((merged['y'] - merged['yhat']) / merged['y'])) * 100
    
    print(f"\nTraining Metrics:")
    print(f"  MAE:  ${mae:,.2f}")
    print(f"  RMSE: ${rmse:,.2f}")
    print(f"  MAPE: {mape:.1f}%")
    
    return model, {'mae': mae, 'rmse': rmse, 'mape': mape}

def save_model(model, filepath):
    """Save model to pickle file."""
    print(f"\nSaving model to {filepath}...")
    with open(filepath, 'wb') as f:
        pickle.dump(model, f)
    print(f"Model saved: {Path(filepath).stat().st_size / 1024:.1f} KB")

def register_to_snowflake(session, model_path, model_name="COST_PROPHET_MODEL"):
    """Register model to Snowflake Model Registry."""
    print(f"\nRegistering model to Snowflake...")
    
    from snowflake.ml.registry import Registry
    
    # Load the model
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    
    # Create registry
    registry = Registry(session=session, database_name="WORKSHOP_DB", schema_name="DEMO")
    
    # Create sample input for schema inference
    sample_input = pd.DataFrame({
        'ds': pd.date_range('2026-01-01', periods=30, freq='D')
    })
    
    # Log model
    mv = registry.log_model(
        model=model,
        model_name=model_name,
        version_name=None,  # Auto-generate
        sample_input_data=sample_input,
        comment="Prophet cost forecasting model for cloud billing"
    )
    
    print(f"Model registered: {model_name}")
    print(f"Version: {mv.version_name}")
    
    return mv

def main():
    print("="*60)
    print("COST FORECASTING MODEL - PROPHET")
    print("="*60)
    
    # Connect to Snowflake
    session = create_snowpark_session()
    print(f"Connected to: {session.get_current_account()}")
    
    # Load data
    df = load_training_data(session)
    
    # Train model for EC2 (our primary service)
    model, metrics = train_prophet_model(df, service='EC2')
    
    # Save model locally
    model_path = '/Users/jdemlow/Customers/Blackline/coco_demo/model/cost_prophet_model.pkl'
    save_model(model, model_path)
    
    # Register to Snowflake
    try:
        mv = register_to_snowflake(session, model_path)
        print(f"\n{'='*60}")
        print("SUCCESS - Model registered to Snowflake Model Registry")
        print(f"{'='*60}")
    except Exception as e:
        print(f"\nWarning: Could not register to Snowflake: {e}")
        print("Model saved locally - can be registered manually")
    
    session.close()

if __name__ == "__main__":
    main()
