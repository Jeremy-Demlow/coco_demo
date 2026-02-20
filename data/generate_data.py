"""
Generate 100,000 synthetic fraud transaction records for ML model training.
Outputs CSV file to be loaded into Snowflake TRANSACTIONS table.

Table Schema:
- TRANSACTION_ID, CUSTOMER_ID, CUSTOMER_NAME, TRANSACTION_DATE, TRANSACTION_TYPE
- AMOUNT, MERCHANT, CHANNEL, LOCATION, IS_FLAGGED, IS_FRAUD, NOTES_TEXT
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
FLAG_RATE = 0.15   # 15% flagged (some are fraud, some are false positives)

# Reference data
TRANSACTION_TYPES = ['Purchase', 'Transfer', 'Withdrawal', 'Payment', 'Wire', 'Deposit', 'Refund']
CHANNELS = ['Online', 'Mobile', 'ATM', 'Branch', 'Phone']
MERCHANTS = ['Amazon', 'Walmart', 'Target', 'BestBuy', 'Costco', 'HomeDepot', 
             'Starbucks', 'McDonalds', 'Shell', 'Chevron', 'Apple', 'Netflix',
             'Uber', 'Lyft', 'DoorDash', 'Unknown', 'International_Vendor']
LOCATIONS = ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
             'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose',
             'Austin', 'Miami', 'Seattle', 'Denver', 'Boston', 'Foreign']

FIRST_NAMES = ['James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 
               'Linda', 'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan',
               'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen', 'Christopher',
               'Nancy', 'Daniel', 'Lisa', 'Matthew', 'Betty', 'Anthony', 'Margaret']
LAST_NAMES = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
              'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
              'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin']

# Notes templates for different scenarios
FRAUD_NOTES = [
    "Unauthorized transaction reported by customer. Account temporarily locked.",
    "Account takeover suspected - password changed from unknown device.",
    "Multiple failed authentication attempts before transaction. Fraud signature detected.",
    "Customer denies making this transaction. Chargeback initiated.",
    "Suspicious IP address detected - VPN from high-risk country.",
    "Velocity check failed - 15 transactions in 30 minutes.",
    "Card present transaction but customer was traveling - geo anomaly.",
    "Transaction pattern inconsistent with customer history.",
    "Merchant flagged for high fraud rate. Manual review required.",
    "Device fingerprint mismatch - new device, new location, high amount.",
]

FLAGGED_NOTES = [
    "System flagged for review - amount exceeds daily limit.",
    "Flagged: First transaction with this merchant.",
    "Automated flag: Unusual transaction time (3 AM local).",
    "Risk score elevated due to recent account changes.",
    "Flagged for manual review - international transaction.",
    "Velocity alert: Multiple transactions to same merchant.",
    "Amount significantly higher than customer average.",
    "New payment method used - flagged for verification.",
    "Transaction originated from mobile device in new city.",
    "Flagged: Merchant category code mismatch.",
]

NORMAL_NOTES = [
    "Regular recurring payment processed successfully.",
    "Customer-initiated transfer to known recipient.",
    "Standard purchase - no anomalies detected.",
    "Verified transaction - customer confirmed via app.",
    "Routine bill payment to utility company.",
    "Subscription renewal - expected transaction.",
    "Point of sale purchase - chip verified.",
    "Mobile wallet payment - biometric authenticated.",
    "Direct deposit from employer - verified source.",
    "",  # Some transactions have no notes
    "",
    "",
]


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


def generate_name() -> str:
    """Generate a random customer name."""
    return f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"


def generate_notes(is_fraud: bool, is_flagged: bool) -> str:
    """Generate appropriate notes based on transaction status."""
    if is_fraud:
        return random.choice(FRAUD_NOTES)
    elif is_flagged:
        return random.choice(FLAGGED_NOTES)
    else:
        return random.choice(NORMAL_NOTES)


def generate_transaction(idx: int) -> dict:
    """Generate a single transaction record."""
    
    # Determine if fraudulent (5% base rate)
    is_fraud = random.random() < FRAUD_RATE
    
    # Flagged includes all fraud + some false positives
    is_flagged = is_fraud or (random.random() < (FLAG_RATE - FRAUD_RATE))
    
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
    
    # Generate customer ID (reuse some customers)
    customer_id = f'CUST_{random.randint(1, 10000):05d}'
    
    return {
        'TRANSACTION_ID': f'TXN_{idx:07d}',
        'CUSTOMER_ID': customer_id,
        'CUSTOMER_NAME': generate_name(),
        'TRANSACTION_DATE': timestamp.strftime('%Y-%m-%d'),
        'TRANSACTION_TYPE': transaction_type,
        'AMOUNT': amount,
        'MERCHANT': merchant,
        'CHANNEL': channel,
        'LOCATION': location,
        'IS_FLAGGED': is_flagged,
        'IS_FRAUD': is_fraud,
        'NOTES_TEXT': generate_notes(is_fraud, is_flagged),
    }


def main():
    print(f"Generating {NUM_RECORDS:,} synthetic transactions...")
    
    # Generate all transactions
    transactions = [generate_transaction(i) for i in range(NUM_RECORDS)]
    
    # Create DataFrame
    df = pd.DataFrame(transactions)
    
    # Summary statistics
    fraud_count = df['IS_FRAUD'].sum()
    flagged_count = df['IS_FLAGGED'].sum()
    print(f"\nDataset Summary:")
    print(f"  Total records: {len(df):,}")
    print(f"  Fraud cases: {fraud_count:,} ({fraud_count/len(df)*100:.1f}%)")
    print(f"  Flagged cases: {flagged_count:,} ({flagged_count/len(df)*100:.1f}%)")
    print(f"  Amount range: ${df['AMOUNT'].min():.2f} - ${df['AMOUNT'].max():,.2f}")
    print(f"  Average amount: ${df['AMOUNT'].mean():,.2f}")
    print(f"  Notes populated: {(df['NOTES_TEXT'] != '').sum():,}")
    
    # Save to CSV
    output_file = 'transactions_100k.csv'
    df.to_csv(output_file, index=False)
    print(f"\nSaved to {output_file}")
    
    # Show sample
    print("\nSample records:")
    sample_cols = ['TRANSACTION_ID', 'CUSTOMER_NAME', 'AMOUNT', 'IS_FLAGGED', 'IS_FRAUD', 'NOTES_TEXT']
    print(df[sample_cols].head(10).to_string(index=False))


if __name__ == "__main__":
    main()
