"""
Generate 100,000 synthetic fraud transaction records for ML model training.
Outputs CSV file to be loaded into Snowflake TRANSACTIONS table.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set seed for reproducibility
np.random.seed(42)
random.seed(42)

# Configuration
NUM_RECORDS = 100_000
FRAUD_RATE = 0.05  # 5% fraud rate

# Reference data
TRANSACTION_TYPES = ['Purchase', 'Transfer', 'Withdrawal', 'Payment', 'Wire', 'Deposit']
CHANNELS = ['Online', 'Mobile', 'ATM', 'Branch', 'Phone']
MERCHANTS = ['Amazon', 'Walmart', 'Target', 'BestBuy', 'Costco', 'HomeDepot', 
             'Starbucks', 'McDonalds', 'Shell', 'Chevron', 'Apple', 'Netflix',
             'Uber', 'Lyft', 'DoorDash', 'Unknown', 'International_Vendor']
LOCATIONS = ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
             'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose',
             'Austin', 'Miami', 'Seattle', 'Denver', 'Boston', 'Foreign']

def generate_amount(is_fraud: bool) -> float:
    """Generate transaction amount - fraud transactions tend to be higher."""
    if is_fraud:
        # Fraudulent transactions: bimodal - small test charges or large amounts
        if random.random() < 0.3:
            return round(random.uniform(0.01, 10.0), 2)  # Test charge
        else:
            return round(np.random.exponential(2000) + 500, 2)  # Large amount
    else:
        # Normal transactions: log-normal distribution
        return round(np.random.lognormal(mean=4.0, sigma=1.2), 2)

def generate_transaction(idx: int) -> dict:
    """Generate a single transaction record."""
    
    # Determine if fraudulent
    is_fraud = random.random() < FRAUD_RATE
    
    # Generate base fields
    transaction_type = random.choice(TRANSACTION_TYPES)
    channel = random.choice(CHANNELS)
    merchant = random.choice(MERCHANTS)
    location = random.choice(LOCATIONS)
    amount = generate_amount(is_fraud)
    
    # Fraud patterns - certain combinations are more likely fraud
    if is_fraud:
        # Increase likelihood of suspicious patterns
        if random.random() < 0.4:
            channel = 'Online'
            transaction_type = random.choice(['Wire', 'Transfer'])
        if random.random() < 0.3:
            merchant = random.choice(['Unknown', 'International_Vendor'])
        if random.random() < 0.25:
            location = 'Foreign'
    
    # Generate timestamp within last 90 days
    days_ago = random.randint(0, 90)
    hours_ago = random.randint(0, 23)
    minutes_ago = random.randint(0, 59)
    timestamp = datetime.now() - timedelta(days=days_ago, hours=hours_ago, minutes=minutes_ago)
    
    return {
        'TRANSACTION_ID': f'TXN_{idx:07d}',
        'CUSTOMER_ID': f'CUST_{random.randint(1, 10000):05d}',
        'AMOUNT': amount,
        'TRANSACTION_TYPE': transaction_type,
        'CHANNEL': channel,
        'MERCHANT': merchant,
        'LOCATION': location,
        'TIMESTAMP': timestamp.strftime('%Y-%m-%d %H:%M:%S'),
        'IS_FRAUD': is_fraud
    }

def main():
    print(f"Generating {NUM_RECORDS:,} synthetic transactions...")
    
    # Generate all transactions
    transactions = [generate_transaction(i) for i in range(NUM_RECORDS)]
    
    # Create DataFrame
    df = pd.DataFrame(transactions)
    
    # Summary statistics
    fraud_count = df['IS_FRAUD'].sum()
    print(f"\nDataset Summary:")
    print(f"  Total records: {len(df):,}")
    print(f"  Fraud cases: {fraud_count:,} ({fraud_count/len(df)*100:.1f}%)")
    print(f"  Non-fraud cases: {len(df) - fraud_count:,}")
    print(f"  Amount range: ${df['AMOUNT'].min():.2f} - ${df['AMOUNT'].max():,.2f}")
    print(f"  Average amount: ${df['AMOUNT'].mean():,.2f}")
    
    # Save to CSV
    output_file = 'transactions_100k.csv'
    df.to_csv(output_file, index=False)
    print(f"\nSaved to {output_file}")
    
    # Show sample
    print("\nSample records:")
    print(df.head(10).to_string(index=False))

if __name__ == "__main__":
    main()
