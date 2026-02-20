"""
Cost Forecasting Model - Simple time series forecasting.
Uses exponential smoothing for robust forecasting and registers to Snowflake.
"""

import sys
sys.path.insert(0, '/Users/jdemlow/Customers/Blackline/coco_demo/model')

from snowpark_session import create_snowpark_session
import pandas as pd
import numpy as np
from statsmodels.tsa.holtwinters import ExponentialSmoothing
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
    
    # Convert columns (Snowflake returns uppercase)
    df['ds'] = pd.to_datetime(df['DS'])
    df['y'] = df['Y'].astype(float)
    df['service'] = df['SERVICE']
    
    print(f"Loaded {len(df):,} rows")
    print(f"Date range: {df['ds'].min().date()} to {df['ds'].max().date()}")
    print(f"Services: {df['service'].nunique()}")
    
    return df[['ds', 'y', 'service']]

def train_ets_model(df, service='EC2'):
    """Train an Exponential Smoothing model for a specific service."""
    print(f"\nTraining ETS model for {service}...")
    
    # Filter to specific service and sort by date
    service_df = df[df['service'] == service][['ds', 'y']].copy()
    service_df = service_df.sort_values('ds').set_index('ds')
    
    if len(service_df) == 0:
        raise ValueError(f"No data found for service: {service}")
    
    print(f"Training data: {len(service_df)} rows")
    
    # Exponential Smoothing with trend and seasonality
    model = ExponentialSmoothing(
        service_df['y'],
        trend='add',
        seasonal='add',
        seasonal_periods=7,  # Weekly seasonality
        damped_trend=True
    ).fit(optimized=True)
    
    # Calculate in-sample metrics
    fitted = model.fittedvalues
    actual = service_df['y'].values
    
    mae = np.mean(np.abs(actual - fitted))
    rmse = np.sqrt(np.mean((actual - fitted)**2))
    mape = np.mean(np.abs((actual - fitted) / actual)) * 100
    
    print(f"\nTraining Metrics:")
    print(f"  MAE:  ${mae:,.2f}")
    print(f"  RMSE: ${rmse:,.2f}")
    print(f"  MAPE: {mape:.1f}%")
    
    return model, service_df, {'mae': mae, 'rmse': rmse, 'mape': mape}

def forecast(model, periods=30):
    """Generate future forecast."""
    return model.forecast(periods)

def save_model(model, filepath):
    """Save model to pickle file."""
    print(f"\nSaving model to {filepath}...")
    with open(filepath, 'wb') as f:
        pickle.dump(model, f)
    print(f"Model saved: {Path(filepath).stat().st_size / 1024:.1f} KB")

def register_to_snowflake(session, model_path, model_name="COST_FORECAST_MODEL"):
    """Register model to Snowflake Model Registry."""
    print(f"\nRegistering model to Snowflake Model Registry...")
    
    from snowflake.ml.registry import Registry
    
    # Load the model
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    
    # Create registry
    registry = Registry(session=session, database_name="WORKSHOP_DB", schema_name="DEMO")
    
    # Log model with custom model class
    mv = registry.log_model(
        model=model,
        model_name=model_name,
        version_name=None,  # Auto-generate
        comment="ETS cost forecasting model for cloud billing"
    )
    
    print(f"Model registered: {model_name}")
    print(f"Version: {mv.version_name}")
    
    return mv

def main():
    print("="*60)
    print("COST FORECASTING MODEL - EXPONENTIAL SMOOTHING")
    print("="*60)
    
    # Connect to Snowflake
    session = create_snowpark_session()
    print(f"Connected to: {session.get_current_account()}")
    
    # Load data
    df = load_training_data(session)
    
    # Train model for EC2 (our primary service)
    model, train_data, metrics = train_ets_model(df, service='EC2')
    
    # Demo forecast
    print("\n30-day Forecast for EC2:")
    future = forecast(model, periods=30)
    print(f"  Next 7 days avg: ${future[:7].mean():,.2f}/day")
    print(f"  30-day total:    ${future.sum():,.2f}")
    
    # Save model locally
    model_path = '/Users/jdemlow/Customers/Blackline/coco_demo/model/cost_ets_model.pkl'
    save_model(model, model_path)
    
    # Register to Snowflake
    try:
        mv = register_to_snowflake(session, model_path)
        print(f"\n{'='*60}")
        print("SUCCESS - Model registered to Snowflake Model Registry")
        print(f"{'='*60}")
    except Exception as e:
        print(f"\nWarning: Could not register to Snowflake: {e}")
        print("Model saved locally at:", model_path)
    
    session.close()

if __name__ == "__main__":
    main()
