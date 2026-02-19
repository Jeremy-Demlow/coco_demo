"""
Fraud Detection Model - Blackline Demo
======================================
sklearn Pipeline + Hyperparameter Tuning + Experiment Tracking + Model Registry
"""

import pandas as pd
import numpy as np
import os
from datetime import datetime

from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix, ConfusionMatrixDisplay, make_scorer
import matplotlib.pyplot as plt
import tempfile

# Snowflake connection
os.environ['SNOWFLAKE_CONNECTION_NAME'] = 'myconnection'
from snowpark_session import create_snowpark_session

print("=" * 60)
print("FRAUD DETECTION MODEL WITH HYPERPARAMETER TUNING")
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

# 4. Build pipeline
print("\n[4] Building pipeline...")
preprocessor = ColumnTransformer([
    ('num', StandardScaler(), numeric_features),
    ('cat', OneHotEncoder(handle_unknown='ignore', sparse_output=False), categorical_features)
])

pipeline = Pipeline([
    ('preprocessor', preprocessor),
    ('classifier', LogisticRegression(random_state=42, max_iter=1000))
])

# 5. Hyperparameter tuning
print("\n[5] Hyperparameter tuning with GridSearchCV...")

param_grid = {
    'classifier__C': [0.01, 0.1, 1.0, 10.0],
    'classifier__class_weight': [None, 'balanced', {0: 1, 1: 5}, {0: 1, 1: 10}],
    'classifier__penalty': ['l1', 'l2'],
    'classifier__solver': ['saga']  # saga supports both l1 and l2
}

# Use ROC-AUC as scoring metric
grid_search = GridSearchCV(
    pipeline,
    param_grid,
    cv=5,
    scoring='roc_auc',
    n_jobs=-1,
    verbose=1
)

grid_search.fit(X_train, y_train)

print(f"\n    Best params: {grid_search.best_params_}")
print(f"    Best CV ROC-AUC: {grid_search.best_score_:.3f}")

# Get best model
best_pipeline = grid_search.best_estimator_

# 6. Initialize experiment tracking
print("\n[6] Setting up experiment tracking...")
from snowflake.ml.experiment import ExperimentTracking
from snowflake.ml.model.model_signature import infer_signature

exp = ExperimentTracking(session=session)
exp.set_experiment("FRAUD_DETECTION")

run_name = f"tuned_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
print(f"    Experiment: FRAUD_DETECTION")
print(f"    Run: {run_name}")

# 7. Evaluate and log with experiment tracking
print("\n[7] Evaluating and logging...")

with exp.start_run(run_name):
    # Log all hyperparameters including best ones
    params_to_log = {
        "model_type": "LogisticRegression",
        "tuning_method": "GridSearchCV",
        "cv_folds": 5,
        "scoring": "roc_auc",
        "n_samples": len(df),
        "n_features": len(numeric_features + categorical_features),
        "best_C": grid_search.best_params_['classifier__C'],
        "best_penalty": grid_search.best_params_['classifier__penalty'],
        "best_class_weight": str(grid_search.best_params_['classifier__class_weight']),
        "cv_best_score": grid_search.best_score_
    }
    exp.log_params(params_to_log)
    
    # Evaluate on test set
    y_pred = best_pipeline.predict(X_test)
    y_prob = best_pipeline.predict_proba(X_test)[:, 1]
    
    metrics = {
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred),
        "recall": recall_score(y_test, y_pred),
        "f1": f1_score(y_test, y_pred),
        "roc_auc": roc_auc_score(y_test, y_prob)
    }
    
    # Log metrics
    exp.log_metrics(metrics)
    
    print(f"    ROC-AUC: {metrics['roc_auc']:.3f}")
    print(f"    Accuracy: {metrics['accuracy']:.3f}")
    print(f"    Precision: {metrics['precision']:.3f}")
    print(f"    Recall: {metrics['recall']:.3f}")
    print(f"    F1: {metrics['f1']:.3f}")
    
    # Log model with signature
    sig = infer_signature(X_train, y_train)
    exp.log_model(
        best_pipeline,
        model_name="FRAUD_DETECTION_MODEL",
        signatures={"predict": sig}
    )
    
    # Log artifacts
    print("\n[8] Logging artifacts...")
    with tempfile.TemporaryDirectory() as tmpdir:
        # Confusion matrix
        cm_path = f"{tmpdir}/confusion_matrix.png"
        fig, ax = plt.subplots(figsize=(6, 5))
        ConfusionMatrixDisplay.from_predictions(y_test, y_pred, ax=ax, cmap='Blues')
        ax.set_title('Confusion Matrix')
        plt.tight_layout()
        plt.savefig(cm_path, dpi=100)
        plt.close()
        exp.log_artifact(cm_path)
        print("    Logged: confusion_matrix.png")
        
        # Feature importance (LogReg coefficients)
        fi_path = f"{tmpdir}/feature_importance.png"
        feature_names = best_pipeline.named_steps['preprocessor'].get_feature_names_out()
        coefficients = best_pipeline.named_steps['classifier'].coef_[0]
        
        # Top 15 features by absolute coefficient
        top_n = min(15, len(coefficients))
        sorted_idx = np.argsort(np.abs(coefficients))[-top_n:]
        
        fig, ax = plt.subplots(figsize=(10, 6))
        colors = ['red' if c < 0 else 'green' for c in coefficients[sorted_idx]]
        ax.barh(range(len(sorted_idx)), coefficients[sorted_idx], color=colors)
        ax.set_yticks(range(len(sorted_idx)))
        ax.set_yticklabels(feature_names[sorted_idx])
        ax.set_xlabel('Coefficient (green=fraud indicator, red=fraud reducer)')
        ax.set_title('Top 15 Feature Importance (LogReg Coefficients)')
        plt.tight_layout()
        plt.savefig(fi_path, dpi=100)
        plt.close()
        exp.log_artifact(fi_path)
        print("    Logged: feature_importance.png")
        
        # Hyperparameter tuning results
        cv_path = f"{tmpdir}/cv_results.png"
        cv_results = pd.DataFrame(grid_search.cv_results_)
        
        fig, ax = plt.subplots(figsize=(10, 6))
        # Plot mean test scores for each C value, grouped by class_weight
        for cw in param_grid['classifier__class_weight']:
            mask = cv_results['param_classifier__class_weight'] == cw
            subset = cv_results[mask].sort_values('param_classifier__C')
            ax.plot(subset['param_classifier__C'], subset['mean_test_score'], 
                   marker='o', label=f'class_weight={cw}')
        
        ax.set_xscale('log')
        ax.set_xlabel('C (regularization)')
        ax.set_ylabel('Mean CV ROC-AUC')
        ax.set_title('Hyperparameter Tuning Results')
        ax.legend(loc='best', fontsize=8)
        ax.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(cv_path, dpi=100)
        plt.close()
        exp.log_artifact(cv_path)
        print("    Logged: cv_results.png")

# 9. Update model registry
print("\n[9] Updating model registry...")
from snowflake.ml.registry import Registry

registry = Registry(session=session)
model = registry.get_model("FRAUD_DETECTION_MODEL")
versions = model.show_versions()

print(f"    Available versions: {list(versions['name'])}")

# Set latest as default
latest_version = versions.iloc[-1]['name']
model.default = latest_version
print(f"    Set default to: {latest_version}")

# Clean up old versions (keep only latest)
for _, row in versions.iterrows():
    if row['name'] != latest_version:
        try:
            model.delete_version(row['name'])
            print(f"    Deleted old version: {row['name']}")
        except Exception as e:
            print(f"    Could not delete {row['name']}: {e}")

print("\n" + "=" * 60)
print("COMPLETE")
print("=" * 60)
print(f"""
Summary:
  - Experiment: WORKSHOP_DB.DEMO.FRAUD_DETECTION
  - Run: {run_name}
  - Model: WORKSHOP_DB.DEMO.FRAUD_DETECTION_MODEL
  - Default version: {latest_version}
  
Tuning Results:
  - Best C: {grid_search.best_params_['classifier__C']}
  - Best penalty: {grid_search.best_params_['classifier__penalty']}
  - Best class_weight: {grid_search.best_params_['classifier__class_weight']}
  - CV ROC-AUC: {grid_search.best_score_:.3f}
  - Test ROC-AUC: {metrics['roc_auc']:.3f}
  - Precision: {metrics['precision']:.3f}
  - Recall: {metrics['recall']:.3f}
""")
