"""
Generate 100,000 synthetic fraud transaction records for ML model training.
Outputs CSV file to be loaded into Snowflake TRANSACTIONS table.

Table Schema:
- TRANSACTION_ID, CUSTOMER_ID, CUSTOMER_NAME, TRANSACTION_DATE, TRANSACTION_TYPE
- AMOUNT, MERCHANT, CHANNEL, LOCATION, IS_FLAGGED, IS_FRAUD, NOTES_TEXT

Fixes applied:
- Customer names cached per CUSTOMER_ID (consistent identity)
- Parameterized notes include transaction details (better for Cortex Search)
- Merchant/channel constraints (realistic combinations)
- Fixed base date for reproducibility
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

# FIXED base date for reproducibility (instead of datetime.now())
BASE_DATE = datetime(2026, 2, 1)

# Reference data
TRANSACTION_TYPES = ['Purchase', 'Transfer', 'Withdrawal', 'Payment', 'Wire', 'Deposit', 'Refund']
CHANNELS = ['Online', 'Mobile App', 'ATM', 'In-Store', 'Phone']

# Merchant-Channel constraints (realistic combinations)
MERCHANT_CHANNELS = {
    'Amazon': ['Online', 'Mobile App'],
    'Walmart': ['Online', 'Mobile App', 'In-Store'],
    'Target': ['Online', 'Mobile App', 'In-Store'],
    'BestBuy': ['Online', 'Mobile App', 'In-Store'],
    'Costco': ['Online', 'In-Store'],
    'HomeDepot': ['Online', 'In-Store'],
    'Starbucks': ['Mobile App', 'In-Store'],
    'McDonalds': ['Mobile App', 'In-Store'],
    'Shell': ['In-Store', 'ATM'],
    'Chevron': ['In-Store', 'ATM'],
    'Apple': ['Online', 'Mobile App', 'In-Store'],
    'Netflix': ['Online', 'Mobile App'],
    'Uber': ['Mobile App'],
    'Lyft': ['Mobile App'],
    'DoorDash': ['Mobile App', 'Online'],
    'Unknown': ['Online', 'Phone', 'ATM'],
    'International_Vendor': ['Online', 'Phone'],
    'Bank_ATM': ['ATM'],
    'Utility_Company': ['Online', 'Phone'],
    'Insurance_Co': ['Online', 'Phone'],
}

MERCHANTS = list(MERCHANT_CHANNELS.keys())

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

# Customer cache for consistent names per customer_id
CUSTOMER_CACHE = {}

def get_customer(customer_id: str) -> dict:
    """Get or create consistent customer details for a customer_id."""
    if customer_id not in CUSTOMER_CACHE:
        CUSTOMER_CACHE[customer_id] = {
            'name': f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            'home_location': random.choice(LOCATIONS[:-1]),  # Exclude 'Foreign' as home
            'preferred_channel': random.choice(['Online', 'Mobile App', 'In-Store']),
        }
    return CUSTOMER_CACHE[customer_id]


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


def generate_notes(txn_id: str, customer_name: str, amount: float, merchant: str,
                   channel: str, location: str, is_fraud: bool, is_flagged: bool) -> str:
    """Generate contextual notes with transaction details for better search."""
    
    if is_fraud:
        templates = [
            f"ALERT: Customer {customer_name} reported unauthorized transaction {txn_id}. Amount ${amount:.2f} at {merchant} flagged for investigation. Account temporarily locked pending review.",
            f"FRAUD CONFIRMED: Transaction {txn_id} - Account takeover suspected. {customer_name}'s password was changed from unknown device before ${amount:.2f} charge at {merchant}.",
            f"INVESTIGATION: {txn_id} - Multiple failed authentication attempts before this ${amount:.2f} transaction. Fraud signature detected for {customer_name}.",
            f"CHARGEBACK: Customer {customer_name} denies transaction {txn_id} for ${amount:.2f} at {merchant}. Dispute filed, funds reversed.",
            f"SECURITY: Suspicious IP detected for {txn_id}. VPN from high-risk country used. {customer_name} charged ${amount:.2f} at {merchant}.",
            f"VELOCITY FRAUD: {txn_id} failed velocity check - 15 transactions in 30 minutes for {customer_name}. This ${amount:.2f} charge blocked.",
            f"GEO ANOMALY: Card present at {merchant} ({location}) but {customer_name} confirmed traveling. Transaction {txn_id} for ${amount:.2f} flagged.",
            f"PATTERN MISMATCH: {txn_id} inconsistent with {customer_name}'s history. ${amount:.2f} at {merchant} via {channel} - unusual behavior.",
            f"HIGH RISK MERCHANT: {merchant} flagged for elevated fraud. Transaction {txn_id} by {customer_name} for ${amount:.2f} requires manual review.",
            f"DEVICE FRAUD: New device, new location ({location}), high amount (${amount:.2f}). {customer_name}'s transaction {txn_id} at {merchant} blocked.",
        ]
        return random.choice(templates)
    
    elif is_flagged:
        templates = [
            f"FLAGGED: Transaction {txn_id} by {customer_name} for ${amount:.2f} exceeds daily limit. Pending approval.",
            f"REVIEW NEEDED: First transaction for {customer_name} with {merchant}. Amount ${amount:.2f} flagged for verification.",
            f"TIME ANOMALY: {txn_id} at unusual hour (3 AM) for {customer_name}. ${amount:.2f} at {merchant} flagged.",
            f"RISK ELEVATED: Recent account changes for {customer_name}. Transaction {txn_id} for ${amount:.2f} needs review.",
            f"INTERNATIONAL FLAG: {txn_id} from {location} for {customer_name}. ${amount:.2f} at {merchant} requires verification.",
            f"VELOCITY ALERT: Multiple transactions by {customer_name} to {merchant}. Latest: {txn_id} for ${amount:.2f}.",
            f"AMOUNT ALERT: ${amount:.2f} significantly exceeds {customer_name}'s average. Transaction {txn_id} at {merchant} flagged.",
            f"NEW PAYMENT METHOD: {customer_name} used new {channel} method for {txn_id}. ${amount:.2f} at {merchant} pending verification.",
            f"LOCATION CHANGE: {customer_name} transacting from {location} (new city). {txn_id} for ${amount:.2f} flagged.",
            f"MCC MISMATCH: {merchant} category unusual for {customer_name}. Transaction {txn_id} for ${amount:.2f} flagged.",
        ]
        return random.choice(templates)
    
    else:
        templates = [
            f"Processed: Regular payment by {customer_name} - {txn_id} for ${amount:.2f} at {merchant}.",
            f"Verified: {customer_name} confirmed {txn_id} via {channel}. ${amount:.2f} at {merchant} approved.",
            f"Standard: Purchase {txn_id} by {customer_name} at {merchant} for ${amount:.2f}. No anomalies.",
            f"Recurring: Expected transaction {txn_id} for {customer_name}. ${amount:.2f} to {merchant}.",
            f"Routine: {channel} payment {txn_id} by {customer_name}. ${amount:.2f} at {merchant} cleared.",
            f"Approved: {customer_name}'s {txn_id} - ${amount:.2f} at {merchant} via {channel}.",
            f"Complete: Transaction {txn_id} processed for {customer_name}. ${amount:.2f} at {merchant}.",
            f"Normal: {customer_name} purchase at {merchant} in {location}. {txn_id} for ${amount:.2f}.",
            "",  # Some transactions have no notes (10% chance via multiple empty entries)
            "",
            "",
        ]
        return random.choice(templates)


def generate_transaction(idx: int) -> dict:
    """Generate a single transaction record."""
    
    # Determine if fraudulent (5% base rate)
    is_fraud = random.random() < FRAUD_RATE
    
    # Flagged includes all fraud + some false positives
    is_flagged = is_fraud or (random.random() < (FLAG_RATE - FRAUD_RATE))
    
    # Generate customer (consistent per customer_id)
    customer_id = f'CUST_{random.randint(1, 10000):05d}'
    customer = get_customer(customer_id)
    customer_name = customer['name']
    
    # Generate base fields with realistic constraints
    transaction_type = random.choice(TRANSACTION_TYPES)
    merchant = random.choice(MERCHANTS)
    channel = random.choice(MERCHANT_CHANNELS[merchant])  # Valid channel for merchant
    location = customer['home_location'] if random.random() < 0.8 else random.choice(LOCATIONS)
    amount = generate_amount(is_fraud)
    
    # Fraud patterns - certain combinations are more likely fraud
    if is_fraud:
        # Increase likelihood of suspicious patterns
        if random.random() < 0.4:
            channel = 'Online'
            transaction_type = random.choice(['Wire', 'Transfer'])
            merchant = random.choice(['Unknown', 'International_Vendor'])
        if random.random() < 0.25:
            location = 'Foreign'
    
    # Generate timestamp within last 90 days from FIXED base date
    days_ago = random.randint(0, 90)
    hours_ago = random.randint(0, 23)
    minutes_ago = random.randint(0, 59)
    timestamp = BASE_DATE - timedelta(days=days_ago, hours=hours_ago, minutes=minutes_ago)
    
    # Generate contextual notes
    notes = generate_notes(
        txn_id=f'TXN_{idx:07d}',
        customer_name=customer_name,
        amount=amount,
        merchant=merchant,
        channel=channel,
        location=location,
        is_fraud=is_fraud,
        is_flagged=is_flagged
    )
    
    return {
        'TRANSACTION_ID': f'TXN_{idx:07d}',
        'CUSTOMER_ID': customer_id,
        'CUSTOMER_NAME': customer_name,
        'TRANSACTION_DATE': timestamp.strftime('%Y-%m-%d'),
        'TRANSACTION_TYPE': transaction_type,
        'AMOUNT': amount,
        'MERCHANT': merchant,
        'CHANNEL': channel,
        'LOCATION': location,
        'IS_FLAGGED': is_flagged,
        'IS_FRAUD': is_fraud,
        'NOTES_TEXT': notes,
    }


def main():
    print(f"Generating {NUM_RECORDS:,} synthetic transactions...")
    print(f"Base date: {BASE_DATE.strftime('%Y-%m-%d')} (fixed for reproducibility)")
    
    # Generate all transactions
    transactions = [generate_transaction(i) for i in range(NUM_RECORDS)]
    
    # Create DataFrame
    df = pd.DataFrame(transactions)
    
    # Summary statistics
    fraud_count = df['IS_FRAUD'].sum()
    flagged_count = df['IS_FLAGGED'].sum()
    unique_customers = df['CUSTOMER_ID'].nunique()
    unique_notes = df['NOTES_TEXT'].nunique()
    
    print(f"\nDataset Summary:")
    print(f"  Total records: {len(df):,}")
    print(f"  Unique customers: {unique_customers:,}")
    print(f"  Fraud cases: {fraud_count:,} ({fraud_count/len(df)*100:.1f}%)")
    print(f"  Flagged cases: {flagged_count:,} ({flagged_count/len(df)*100:.1f}%)")
    print(f"  Amount range: ${df['AMOUNT'].min():.2f} - ${df['AMOUNT'].max():,.2f}")
    print(f"  Average amount: ${df['AMOUNT'].mean():,.2f}")
    print(f"  Unique notes: {unique_notes:,} (for Cortex Search)")
    print(f"  Empty notes: {(df['NOTES_TEXT'] == '').sum():,}")
    
    # Verify customer name consistency
    customer_consistency = df.groupby('CUSTOMER_ID')['CUSTOMER_NAME'].nunique()
    inconsistent = (customer_consistency > 1).sum()
    print(f"  Customer name consistency: {'PASS' if inconsistent == 0 else f'FAIL ({inconsistent} inconsistent)'}")
    
    # Save to CSV
    output_file = 'transactions_100k.csv'
    df.to_csv(output_file, index=False)
    print(f"\nSaved to {output_file}")
    
    # Show sample
    print("\nSample records:")
    sample_cols = ['TRANSACTION_ID', 'CUSTOMER_NAME', 'AMOUNT', 'IS_FLAGGED', 'IS_FRAUD']
    print(df[sample_cols].head(5).to_string(index=False))
    
    print("\nSample notes (for Cortex Search):")
    for note in df[df['NOTES_TEXT'] != '']['NOTES_TEXT'].head(3):
        print(f"  • {note[:100]}...")


if __name__ == "__main__":
    main()
