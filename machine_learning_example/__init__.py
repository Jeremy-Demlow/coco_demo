"""
Anomaly Detection ML Package for Snowflake Reconciliation Data.

This package provides modular components for building anomaly detection pipelines:
- Data exploration and EDA utilities
- Feature engineering and feature store creation
- Model training with hyperparameter tuning
- Experiment tracking integration
- Model registry and deployment utilities
"""

__version__ = "0.1.0"
__author__ = "ML Team"

from machine_learning_example.features import FeatureEngineer
from machine_learning_example.models import AnomalyDetectorPipeline
from machine_learning_example.evaluation import ModelEvaluator
from machine_learning_example.registry import ModelRegistryManager
