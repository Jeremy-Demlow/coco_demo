#!/usr/bin/env python3
"""
Generate FOCUS-compliant cloud billing data.

FOCUS (FinOps Open Cost and Usage Specification) is the standard for cloud billing data.
This script generates realistic synthetic data matching the FOCUS schema.

Usage:
    python generate_focus_data.py                    # Generate default 100K rows
    python generate_focus_data.py --rows 50000       # Custom row count
    python generate_focus_data.py --output data.parquet
"""

import argparse
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any
import pandas as pd
import numpy as np

# =============================================================================
# FOCUS SCHEMA CONFIGURATION
# =============================================================================

# AWS Services with categories and typical costs
AWS_SERVICES = {
    "Compute": [
        ("Amazon Elastic Compute Cloud", 0.10, 50.0),
        ("AWS Lambda", 0.01, 5.0),
        ("Amazon ECS", 0.05, 20.0),
        ("Amazon EKS", 0.10, 30.0),
    ],
    "Storage": [
        ("Amazon Simple Storage Service", 0.02, 10.0),
        ("Amazon Elastic Block Store", 0.05, 15.0),
        ("Amazon FSx", 0.10, 25.0),
        ("AWS Backup", 0.01, 5.0),
    ],
    "Databases": [
        ("Amazon Relational Database Service", 0.10, 40.0),
        ("Amazon DynamoDB", 0.05, 20.0),
        ("Amazon ElastiCache", 0.05, 15.0),
        ("Amazon Redshift", 0.20, 80.0),
    ],
    "Networking": [
        ("Amazon Virtual Private Cloud", 0.01, 5.0),
        ("Elastic Load Balancing", 0.02, 10.0),
        ("Amazon CloudFront", 0.01, 8.0),
        ("AWS Direct Connect", 0.05, 20.0),
    ],
    "Management and Governance": [
        ("AmazonCloudWatch", 0.01, 5.0),
        ("AWS CloudTrail", 0.005, 2.0),
        ("AWS Config", 0.005, 3.0),
        ("AWS Systems Manager", 0.01, 4.0),
    ],
    "Security": [
        ("AWS Secrets Manager", 0.01, 3.0),
        ("AWS Key Management Service", 0.005, 2.0),
        ("AWS Certificate Manager", 0.00, 1.0),
        ("Amazon GuardDuty", 0.01, 5.0),
    ],
    "Analytics": [
        ("Amazon Athena", 0.005, 10.0),
        ("Amazon Kinesis", 0.02, 15.0),
        ("AWS Glue", 0.05, 20.0),
        ("Amazon OpenSearch Service", 0.10, 30.0),
    ],
}

# Azure Services with categories
AZURE_SERVICES = {
    "Compute": [
        ("Virtual Machines", 0.10, 50.0),
        ("Azure Functions", 0.01, 5.0),
        ("Azure Kubernetes Service", 0.10, 30.0),
        ("Azure Container Instances", 0.05, 15.0),
    ],
    "Storage": [
        ("Azure Blob Storage", 0.02, 10.0),
        ("Azure Files", 0.03, 12.0),
        ("Azure Disk Storage", 0.05, 15.0),
        ("Azure Data Lake Storage", 0.03, 10.0),
    ],
    "Databases": [
        ("Azure SQL Database", 0.10, 40.0),
        ("Azure Cosmos DB", 0.08, 30.0),
        ("Azure Database for PostgreSQL", 0.08, 25.0),
        ("Azure Cache for Redis", 0.05, 15.0),
    ],
    "Networking": [
        ("Azure Virtual Network", 0.01, 5.0),
        ("Azure Load Balancer", 0.02, 8.0),
        ("Azure CDN", 0.01, 6.0),
        ("Azure ExpressRoute", 0.05, 20.0),
    ],
    "Management and Governance": [
        ("Azure Monitor", 0.01, 5.0),
        ("Azure Policy", 0.005, 2.0),
        ("Azure Automation", 0.01, 4.0),
        ("Azure Resource Manager", 0.00, 1.0),
    ],
    "Security": [
        ("Azure Key Vault", 0.01, 3.0),
        ("Microsoft Defender for Cloud", 0.02, 8.0),
        ("Azure Active Directory", 0.01, 5.0),
        ("Azure Sentinel", 0.03, 15.0),
    ],
}

# Account structure
ACCOUNTS = {
    "AWS": {
        "billing_account": ("123456789012", "Acme Corp Master Payer"),
        "sub_accounts": [
            ("111111111111", "Production - Acme"),
            ("222222222222", "Development - Acme"),
            ("333333333333", "Staging - Acme"),
            ("444444444444", "Sandbox - Acme"),
            ("555555555555", "Shared Services - Acme"),
        ]
    },
    "Azure": {
        "billing_account": ("sub-abc-123", "Acme Corp Azure EA"),
        "sub_accounts": [
            ("sub-prod-001", "Production - Acme"),
            ("sub-dev-002", "Development - Acme"),
            ("sub-stg-003", "Staging - Acme"),
            ("sub-sbx-004", "Sandbox - Acme"),
            ("sub-shr-005", "Shared Services - Acme"),
        ]
    }
}

# Regions
AWS_REGIONS = [
    ("us-east-1", "US East (N. Virginia)"),
    ("us-west-2", "US West (Oregon)"),
    ("eu-west-1", "EU (Ireland)"),
    ("ap-southeast-1", "Asia Pacific (Singapore)"),
]

AZURE_REGIONS = [
    ("eastus", "East US"),
    ("westus2", "West US 2"),
    ("westeurope", "West Europe"),
    ("southeastasia", "Southeast Asia"),
]

# Departments for tag-based allocation
DEPARTMENTS = ["Engineering", "Data Science", "Finance", "Marketing", "Operations"]

# Environments
ENVIRONMENTS = ["Production", "Development", "Staging", "Sandbox"]

# =============================================================================
# DATA GENERATION
# =============================================================================

def generate_resource_id(provider: str, service: str, region: str, account_id: str) -> str:
    """Generate a realistic resource ID/ARN."""
    resource_id = f"{random.randint(100000, 999999)}"
    
    if provider == "AWS":
        service_code = service.lower().replace(" ", "-").replace("amazon ", "")[:20]
        return f"arn:aws:{service_code}:{region}:{account_id}:resource/{resource_id}"
    else:
        service_code = service.lower().replace(" ", "-")[:20]
        return f"/subscriptions/{account_id}/resourceGroups/rg-{service_code}/providers/Microsoft/{resource_id}"


def generate_tags(department: str, environment: str, project: str = None) -> List[tuple]:
    """Generate realistic cost allocation tags."""
    tags = [
        ("Department", department),
        ("Environment", environment),
        ("CostCenter", f"CC-{DEPARTMENTS.index(department) + 100}"),
    ]
    if project:
        tags.append(("Project", project))
    if random.random() > 0.3:
        tags.append(("Owner", f"{department.lower()}-team@acme.com"))
    return tags


def generate_focus_row(
    date: datetime,
    provider: str,
    service_category: str,
    service_name: str,
    base_cost: float,
    account_info: dict,
    region_info: tuple,
    charge_category: str = "Usage",
    pricing_category: str = "Standard",
    has_commitment: bool = False,
) -> Dict[str, Any]:
    """Generate a single FOCUS-compliant row."""
    
    # Account info
    billing_account = account_info["billing_account"]
    sub_account = random.choice(account_info["sub_accounts"])
    
    # Cost calculations
    # Add some daily variance
    daily_variance = random.uniform(0.8, 1.2)
    
    # Weekend discount (less usage)
    if date.weekday() >= 5:
        daily_variance *= 0.6
    
    # List cost (on-demand price)
    list_cost = base_cost * daily_variance
    
    # Billed cost (what you pay)
    if pricing_category == "Committed":
        # Savings plans get ~20-30% discount
        discount = random.uniform(0.20, 0.30)
        billed_cost = list_cost * (1 - discount)
        contracted_cost = billed_cost
    else:
        billed_cost = list_cost
        contracted_cost = 0.0
    
    # Effective cost (amortized for commitments)
    if has_commitment:
        effective_cost = billed_cost * random.uniform(0.95, 1.05)
    else:
        effective_cost = billed_cost
    
    # Tax rows
    if charge_category == "Tax":
        tax_rate = random.uniform(0.05, 0.10)
        billed_cost = base_cost * tax_rate
        list_cost = billed_cost
        effective_cost = billed_cost
        contracted_cost = 0.0
    
    # Credit rows (negative)
    if charge_category == "Credit":
        billed_cost = -abs(base_cost * random.uniform(0.1, 0.5))
        list_cost = 0.0
        effective_cost = billed_cost
        contracted_cost = 0.0
    
    # Department/environment based on account
    if "Production" in sub_account[1]:
        department = random.choice(["Engineering", "Operations"])
        environment = "Production"
    elif "Development" in sub_account[1]:
        department = random.choice(["Engineering", "Data Science"])
        environment = "Development"
    elif "Staging" in sub_account[1]:
        department = "Engineering"
        environment = "Staging"
    elif "Sandbox" in sub_account[1]:
        department = random.choice(DEPARTMENTS)
        environment = "Sandbox"
    else:
        department = random.choice(["Operations", "Finance"])
        environment = "Production"
    
    # Quantity and units based on service
    if "Compute" in service_category:
        consumed_quantity = random.uniform(1, 100)
        consumed_unit = "Hours"
        pricing_unit = "Hours"
    elif "Storage" in service_category:
        consumed_quantity = random.uniform(10, 1000)
        consumed_unit = "GB"
        pricing_unit = "GB-Month"
    elif "Networking" in service_category:
        consumed_quantity = random.uniform(1, 500)
        consumed_unit = "GB"
        pricing_unit = "GB"
    else:
        consumed_quantity = random.uniform(1, 1000)
        consumed_unit = "Requests"
        pricing_unit = "Requests"
    
    # Build row - Using UPPER_SNAKE_CASE for Snowflake compatibility
    row = {
        # Time periods
        "BILLING_PERIOD_START": date.replace(day=1),
        "BILLING_PERIOD_END": (date.replace(day=1) + timedelta(days=32)).replace(day=1),
        "CHARGE_PERIOD_START": date,
        "CHARGE_PERIOD_END": date + timedelta(days=1),
        
        # Costs
        "BILLED_COST": round(billed_cost, 6),
        "EFFECTIVE_COST": round(effective_cost, 6),
        "LIST_COST": round(list_cost, 6),
        "CONTRACTED_COST": round(contracted_cost, 6),
        
        # Provider and service
        "PROVIDER_NAME": provider,
        "PUBLISHER_NAME": "Amazon Web Services, Inc." if provider == "AWS" else "Microsoft Corporation",
        "INVOICE_ISSUER_NAME": "Amazon Web Services, Inc." if provider == "AWS" else "Microsoft Corporation",
        "SERVICE_CATEGORY": service_category,
        "SERVICE_NAME": service_name,
        
        # Account
        "BILLING_ACCOUNT_ID": billing_account[0],
        "BILLING_ACCOUNT_NAME": billing_account[1],
        "BILLING_ACCOUNT_TYPE": "Management",
        "SUB_ACCOUNT_ID": sub_account[0],
        "SUB_ACCOUNT_NAME": sub_account[1],
        "SUB_ACCOUNT_TYPE": "Member",
        
        # Location
        "REGION_ID": region_info[0],
        "REGION_NAME": region_info[1],
        "AVAILABILITY_ZONE": f"{region_info[0]}{'a' if random.random() > 0.5 else 'b'}" if provider == "AWS" else None,
        
        # Charge classification
        "CHARGE_CATEGORY": charge_category,
        "CHARGE_CLASS": None,
        "CHARGE_DESCRIPTION": f"{charge_category} for {service_name}",
        "CHARGE_FREQUENCY": "Usage-Based",
        "PRICING_CATEGORY": pricing_category if charge_category == "Usage" else "Other",
        
        # Currency
        "BILLING_CURRENCY": "USD",
        "PRICING_CURRENCY": "USD",
        
        # Commitment discounts
        "COMMITMENT_DISCOUNT_CATEGORY": "Spend" if has_commitment else None,
        "COMMITMENT_DISCOUNT_ID": f"arn:aws:savingsplans::{billing_account[0]}:savingsplan/sp-{random.randint(10000, 99999)}" if has_commitment and provider == "AWS" else None,
        "COMMITMENT_DISCOUNT_NAME": "Compute Savings Plan" if has_commitment else None,
        "COMMITMENT_DISCOUNT_TYPE": "Savings Plan" if has_commitment and provider == "AWS" else ("Reserved" if has_commitment else None),
        "COMMITMENT_DISCOUNT_STATUS": "Used" if has_commitment else None,
        "COMMITMENT_DISCOUNT_QUANTITY": round(billed_cost * random.uniform(0.1, 0.3), 6) if has_commitment else None,
        "COMMITMENT_DISCOUNT_UNIT": "Dollars" if has_commitment else None,
        
        # Usage
        "CONSUMED_QUANTITY": round(consumed_quantity, 6) if charge_category == "Usage" else None,
        "CONSUMED_UNIT": consumed_unit if charge_category == "Usage" else None,
        "PRICING_QUANTITY": round(consumed_quantity * random.uniform(0.9, 1.1), 6) if charge_category == "Usage" else None,
        "PRICING_UNIT": pricing_unit if charge_category == "Usage" else None,
        
        # Pricing details
        "LIST_UNIT_PRICE": round(list_cost / max(consumed_quantity, 1), 8) if charge_category == "Usage" else None,
        "CONTRACTED_UNIT_PRICE": round(contracted_cost / max(consumed_quantity, 1), 8) if contracted_cost > 0 else None,
        
        # Resource
        "RESOURCE_ID": generate_resource_id(provider, service_name, region_info[0], sub_account[0]) if charge_category == "Usage" else None,
        "RESOURCE_NAME": f"{service_name.split()[0].lower()}-{random.randint(1000, 9999)}" if charge_category == "Usage" else None,
        "RESOURCE_TYPE": None,
        
        # Tags
        "TAGS": generate_tags(department, environment),
        
        # SKU info
        "SKU_ID": f"SKU{random.randint(100000, 999999)}",
        "SKU_METER": f"{service_name[:20]}-{consumed_unit}" if charge_category == "Usage" else None,
        "SKU_PRICE_ID": f"{random.randint(10000, 99999)}.{random.randint(100, 999)}",
        
        # Custom extensions
        "X_DEPARTMENT": department,
        "X_ENVIRONMENT": environment,
        "X_SERVICE_CODE": service_name.replace(" ", ""),
    }
    
    return row


def generate_focus_data(
    num_rows: int = 100000,
    start_date: datetime = None,
    days: int = 365,
    aws_percentage: float = 0.65,
) -> pd.DataFrame:
    """Generate FOCUS-compliant billing dataset."""
    
    if start_date is None:
        start_date = datetime.now() - timedelta(days=days)
    
    print(f"Generating {num_rows:,} FOCUS billing records...")
    print(f"Date range: {start_date.date()} to {(start_date + timedelta(days=days)).date()}")
    print(f"Provider split: AWS {aws_percentage*100:.0f}% / Azure {(1-aws_percentage)*100:.0f}%")
    
    rows = []
    
    # Charge category distribution (realistic)
    charge_weights = [0.98, 0.015, 0.005]  # Usage, Tax, Credit
    charge_categories = ["Usage", "Tax", "Credit"]
    
    # Pricing category for usage rows
    pricing_weights = [0.95, 0.05]  # Standard, Committed
    pricing_categories = ["Standard", "Committed"]
    
    for i in range(num_rows):
        if i % 10000 == 0:
            print(f"  Generated {i:,} rows...")
        
        # Random date
        date = start_date + timedelta(days=random.randint(0, days - 1))
        
        # Provider selection
        if random.random() < aws_percentage:
            provider = "AWS"
            services = AWS_SERVICES
            regions = AWS_REGIONS
            accounts = ACCOUNTS["AWS"]
        else:
            provider = "Azure"
            services = AZURE_SERVICES
            regions = AZURE_REGIONS
            accounts = ACCOUNTS["Azure"]
        
        # Service selection (weighted by cost)
        service_category = random.choice(list(services.keys()))
        service_info = random.choice(services[service_category])
        service_name, min_cost, max_cost = service_info
        base_cost = random.uniform(min_cost, max_cost)
        
        # Charge category
        charge_category = random.choices(charge_categories, weights=charge_weights)[0]
        
        # Pricing category (only for Usage)
        if charge_category == "Usage":
            pricing_category = random.choices(pricing_categories, weights=pricing_weights)[0]
        else:
            pricing_category = "Other"
        
        # Commitment flag
        has_commitment = pricing_category == "Committed"
        
        # Region
        region_info = random.choice(regions)
        
        # Generate row
        row = generate_focus_row(
            date=date,
            provider=provider,
            service_category=service_category,
            service_name=service_name,
            base_cost=base_cost,
            account_info=accounts,
            region_info=region_info,
            charge_category=charge_category,
            pricing_category=pricing_category,
            has_commitment=has_commitment,
        )
        
        rows.append(row)
    
    print(f"  Generated {len(rows):,} rows total")
    
    # Create DataFrame
    df = pd.DataFrame(rows)
    
    # Convert datetime columns - normalize to date (no time component) for Snowflake compatibility
    datetime_cols = ["BILLING_PERIOD_START", "BILLING_PERIOD_END", "CHARGE_PERIOD_START", "CHARGE_PERIOD_END"]
    for col in datetime_cols:
        # Convert to datetime then normalize to midnight
        df[col] = pd.to_datetime(df[col]).dt.normalize()
    
    # Sort by date
    df = df.sort_values("CHARGE_PERIOD_START").reset_index(drop=True)
    
    return df


def print_summary(df: pd.DataFrame):
    """Print summary statistics of generated data."""
    print("\n" + "=" * 70)
    print("GENERATED DATA SUMMARY")
    print("=" * 70)
    
    print(f"\nTotal Rows: {len(df):,}")
    print(f"Date Range: {df['CHARGE_PERIOD_START'].min().date()} to {df['CHARGE_PERIOD_START'].max().date()}")
    print(f"Total BILLED_COST: ${df['BILLED_COST'].sum():,.2f}")
    print(f"Total EFFECTIVE_COST: ${df['EFFECTIVE_COST'].sum():,.2f}")
    
    print("\nBy Provider:")
    for provider, group in df.groupby("PROVIDER_NAME"):
        pct = len(group) / len(df) * 100
        cost = group['BILLED_COST'].sum()
        print(f"  {provider}: {len(group):,} rows ({pct:.1f}%), ${cost:,.2f}")
    
    print("\nBy Service Category:")
    by_cat = df.groupby("SERVICE_CATEGORY")["BILLED_COST"].sum().sort_values(ascending=False)
    for cat, cost in by_cat.head(7).items():
        print(f"  {cat}: ${cost:,.2f}")
    
    print("\nBy Charge Category:")
    for cat, group in df.groupby("CHARGE_CATEGORY"):
        print(f"  {cat}: {len(group):,} rows, ${group['BILLED_COST'].sum():,.2f}")
    
    print("\nBy Pricing Category:")
    for cat, group in df.groupby("PRICING_CATEGORY"):
        print(f"  {cat}: {len(group):,} rows")
    
    print("\nCommitment Discount Coverage:")
    committed = df[df["COMMITMENT_DISCOUNT_STATUS"] == "Used"]
    print(f"  Rows with commitments: {len(committed):,} ({len(committed)/len(df)*100:.1f}%)")
    print(f"  Commitment savings: ${(df['LIST_COST'].sum() - df['BILLED_COST'].sum()):,.2f}")


def main():
    parser = argparse.ArgumentParser(description="Generate FOCUS-compliant billing data")
    parser.add_argument("--rows", type=int, default=100000, help="Number of rows to generate")
    parser.add_argument("--days", type=int, default=365, help="Number of days of data")
    parser.add_argument("--output", default="focus_billing_data.parquet", help="Output file path")
    parser.add_argument("--csv", action="store_true", help="Also output CSV file")
    args = parser.parse_args()
    
    # Generate data
    df = generate_focus_data(num_rows=args.rows, days=args.days)
    
    # Print summary
    print_summary(df)
    
    # Save parquet
    output_path = args.output
    df.to_parquet(output_path, index=False)
    print(f"\nSaved to: {output_path}")
    import os
    print(f"File size: {os.path.getsize(output_path) / 1024 / 1024:.1f} MB")
    
    # Optionally save CSV
    if args.csv:
        csv_path = output_path.replace(".parquet", ".csv")
        df.to_csv(csv_path, index=False)
        print(f"Saved CSV to: {csv_path}")


if __name__ == "__main__":
    main()
