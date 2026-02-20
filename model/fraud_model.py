"""
Fraud Detection Model - Quick Training Version
==============================================
Simplified training for faster demo setup.
Uses sklearn Pipeline + Model Registry (no GridSearchCV for speed).
"""

import pandas as pd
import numpy as np
import os
from datetime import datetime

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix, ConfusionMatrixDisplay
import matplotlib.pyplot as plt
import tempfile

# Snowflake connection
os.environ['SNOWFLAKE_CONNECTION_NAME'] = 'myconnection'
from snowpark_session import create_snowpark_session

print("=" * 60)
print("FRAUD DETECTION MODEL - QUICK TRAINING")
print("=" * 60)

# 1. Connect and load data
print("\n[1] Loading data...")
session = create_snowpark_session()
session.use_database("WORKSHOP_DB")
session.use_schema("DEMO")

df = session.table("TRANSACTIONS").to_pandas()
print(f"    Rows: {len(df):,}, Fraud rate: {df['IS_FRAUD'].mean()*100:.2f}%")

# 2. Prepare features
print("\n[2] Preparing features...")
numeric_features = ['AMOUNT']
categorical_features = ['TRANSACTION_TYPE', 'CHANNEL', 'LOCATION', 'MERCHANT']

y = df['IS_FRAUD'].astype(int)
X = df[numeric_features + categorical_features].copy()

# 3. Train/test split
print("\n[3] Train/test split...")
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print(f"    Train: {len(X_train):,}, Test: {len(X_test):,}")

# 4. Build and train pipeline
print("\n[4] Building and training pipeline...")
preprocessor = ColumnTransformer([
    ('num', StandardScaler(), numeric_features),
    ('cat', OneHotEncoder(handle_unknown='ignore', sparse_output=False), categorical_features)
])

pipeline = Pipeline([
    ('preprocessor', preprocessor),
    ('classifier', LogisticRegression(
        random_state=42, 
        max_iter=1000,
        class_weight='balanced',  # Handle imbalanced classes
        C=1.0,
        solver='lbfgs'
    ))
])

pipeline.fit(X_train, y_train)
print("    Training complete!")

# 5. Evaluate
print("\n[5] Evaluating model...")
y_pred = pipeline.predict(X_test)
y_prob = pipeline.predict_proba(X_test)[:, 1]

metrics = {
    "accuracy": accuracy_score(y_test, y_pred),
    "precision": precision_score(y_test, y_pred),
    "recall": recall_score(y_test, y_pred),
    "f1": f1_score(y_test, y_pred),
    "roc_auc": roc_auc_score(y_test, y_prob)
}

print(f"    ROC-AUC: {metrics['roc_auc']:.3f}")
print(f"    Accuracy: {metrics['accuracy']:.3f}")
print(f"    Precision: {metrics['precision']:.3f}")
print(f"    Recall: {metrics['recall']:.3f}")
print(f"    F1: {metrics['f1']:.3f}")

# 6. Register to Model Registry
print("\n[6] Registering model to Snowflake Model Registry...")
from snowflake.ml.registry import Registry
from snowflake.ml.model.model_signature import infer_signature

registry = Registry(session=session)

# Infer signature from training data
sig = infer_signature(X_train, y_train)

# Log model to registry
model_ref = registry.log_model(
    pipeline,
    model_name="FRAUD_DETECTION_MODEL",
    version_name=f"v_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
    signatures={"predict": sig},
    comment="Logistic Regression fraud detection model"
)

print(f"    Model registered: {model_ref.model_name}")
print(f"    Version: {model_ref.version_name}")

# Set as default version
model = registry.get_model("FRAUD_DETECTION_MODEL")
model.default = model_ref.version_name
print(f"    Set as default version")

# 7. Test inference
print("\n[7] Testing model inference...")
test_sample = X_test.head(5)
mv = model.default
predictions = mv.run(test_sample, function_name="predict")
print(f"    Sample predictions: {predictions['output_feature_0'].tolist()}")

print("\n" + "=" * 60)
print("COMPLETE")
print("=" * 60)
print(f"""
Summary:
  - Model: WORKSHOP_DB.DEMO.FRAUD_DETECTION_MODEL
  - Version: {model_ref.version_name}
  - ROC-AUC: {metrics['roc_auc']:.3f}
  - Precision: {metrics['precision']:.3f}
  - Recall: {metrics['recall']:.3f}
  
To use in SQL:
  SELECT FRAUD_DETECTION_MODEL!PREDICT(amount, txn_type, channel, location, merchant)
  FROM your_table;
""")
