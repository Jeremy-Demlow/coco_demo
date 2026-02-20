"""
Generate synthetic cloud billing data for cost forecasting demo.
Creates realistic AWS/Azure spending patterns with seasonality and trends.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set seed for reproducibility
np.random.seed(42)
random.seed(42)

# Configuration
NUM_DAYS = 365  # 1 year of historical data
NUM_ACCOUNTS = 15
START_DATE = datetime.now() - timedelta(days=NUM_DAYS)

# Cloud services with base costs and variance
AWS_SERVICES = {
    'EC2': {'base': 500, 'variance': 0.3, 'growth': 0.002},
    'S3': {'base': 150, 'variance': 0.15, 'growth': 0.003},
    'RDS': {'base': 300, 'variance': 0.2, 'growth': 0.001},
    'Lambda': {'base': 50, 'variance': 0.5, 'growth': 0.005},
    'EKS': {'base': 400, 'variance': 0.25, 'growth': 0.004},
    'CloudWatch': {'base': 30, 'variance': 0.2, 'growth': 0.001},
    'DynamoDB': {'base': 100, 'variance': 0.35, 'growth': 0.003},
    'ElastiCache': {'base': 120, 'variance': 0.2, 'growth': 0.002},
}

AZURE_SERVICES = {
    'Virtual Machines': {'base': 450, 'variance': 0.3, 'growth': 0.002},
    'Blob Storage': {'base': 120, 'variance': 0.15, 'growth': 0.003},
    'SQL Database': {'base': 280, 'variance': 0.2, 'growth': 0.001},
    'Functions': {'base': 40, 'variance': 0.5, 'growth': 0.005},
    'AKS': {'base': 350, 'variance': 0.25, 'growth': 0.004},
    'Cosmos DB': {'base': 200, 'variance': 0.3, 'growth': 0.003},
}

AWS_REGIONS = ['us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1']
AZURE_REGIONS = ['eastus', 'westus2', 'westeurope', 'southeastasia']

DEPARTMENTS = ['Engineering', 'Data Science', 'Platform', 'Security', 'DevOps']
ENVIRONMENTS = ['Production', 'Staging', 'Development', 'QA']

def get_seasonality_factor(date):
    """Calculate seasonality multiplier based on day of week and month."""
    dow = date.weekday()
    month = date.month
    
    # Weekday factor: higher on weekdays
    weekday_factor = 1.2 if dow < 5 else 0.7
    
    # Monthly factor: Q4 and Q1 tend to be higher
    monthly_factors = {
        1: 1.15, 2: 1.05, 3: 1.0, 4: 0.95, 5: 0.9, 6: 0.85,
        7: 0.9, 8: 0.95, 9: 1.0, 10: 1.1, 11: 1.2, 12: 1.25
    }
    month_factor = monthly_factors[month]
    
    # End of month spike (billing cycles, batch jobs)
    day = date.day
    eom_factor = 1.3 if day >= 28 else 1.0
    
    return weekday_factor * month_factor * eom_factor

def generate_daily_costs(date, day_index, accounts):
    """Generate billing records for a single day."""
    records = []
    seasonality = get_seasonality_factor(date)
    
    for account in accounts:
        cloud = account['cloud']
        services = AWS_SERVICES if cloud == 'AWS' else AZURE_SERVICES
        regions = AWS_REGIONS if cloud == 'AWS' else AZURE_REGIONS
        
        for service_name, config in services.items():
            # Base cost with growth trend
            trend_multiplier = 1 + (config['growth'] * day_index)
            base = config['base'] * trend_multiplier * account['size_factor']
            
            # Add variance
            variance = np.random.normal(0, config['variance'] * base)
            
            # Apply seasonality
            cost = (base + variance) * seasonality
            
            # Occasional anomalies (3% chance)
            if random.random() < 0.03:
                anomaly_type = random.choice(['spike', 'dip'])
                if anomaly_type == 'spike':
                    cost *= random.uniform(1.5, 3.0)
                else:
                    cost *= random.uniform(0.3, 0.6)
            
            # Ensure non-negative
            cost = max(cost, 0)
            
            # Usage quantity (rough approximation)
            usage_quantity = cost / random.uniform(0.05, 0.15)
            
            records.append({
                'BILLING_DATE': date.strftime('%Y-%m-%d'),
                'CLOUD_PROVIDER': cloud,
                'ACCOUNT_ID': account['id'],
                'ACCOUNT_NAME': account['name'],
                'SERVICE': service_name,
                'REGION': random.choice(regions),
                'DEPARTMENT': account['department'],
                'ENVIRONMENT': random.choice(ENVIRONMENTS),
                'USAGE_QUANTITY': round(usage_quantity, 2),
                'COST': round(cost, 2)
            })
    
    return records

def main():
    print("Generating synthetic cloud billing data...")
    
    # Create accounts with different sizes
    accounts = []
    for i in range(NUM_ACCOUNTS):
        cloud = 'AWS' if i < 10 else 'Azure'
        accounts.append({
            'id': f'{cloud[:3].upper()}-{i+1:03d}',
            'name': f'{random.choice(DEPARTMENTS)}-{cloud}-{i+1}',
            'cloud': cloud,
            'department': random.choice(DEPARTMENTS),
            'size_factor': random.uniform(0.5, 2.0)
        })
    
    # Generate daily data
    all_records = []
    for day_idx in range(NUM_DAYS):
        date = START_DATE + timedelta(days=day_idx)
        daily_records = generate_daily_costs(date, day_idx, accounts)
        all_records.extend(daily_records)
        
        if day_idx % 30 == 0:
            print(f"  Generated {day_idx + 1}/{NUM_DAYS} days...")
    
    # Create DataFrame
    df = pd.DataFrame(all_records)
    
    # Summary statistics
    print(f"\nDataset Summary:")
    print(f"  Total records: {len(df):,}")
    print(f"  Date range: {df['BILLING_DATE'].min()} to {df['BILLING_DATE'].max()}")
    print(f"  Total cost: ${df['COST'].sum():,.2f}")
    print(f"  Daily average: ${df.groupby('BILLING_DATE')['COST'].sum().mean():,.2f}")
    print(f"\nCost by Cloud Provider:")
    print(df.groupby('CLOUD_PROVIDER')['COST'].sum().apply(lambda x: f"${x:,.2f}"))
    print(f"\nCost by Service (Top 5):")
    top_services = df.groupby('SERVICE')['COST'].sum().sort_values(ascending=False).head(5)
    for svc, cost in top_services.items():
        print(f"  {svc}: ${cost:,.2f}")
    
    # Save to CSV
    output_file = 'billing_data.csv'
    df.to_csv(output_file, index=False)
    print(f"\nSaved to {output_file}")

if __name__ == "__main__":
    main()
