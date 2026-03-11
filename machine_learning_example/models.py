"""Model training and hyperparameter tuning utilities."""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Any, Tuple
from sklearn.ensemble import IsolationForest
from sklearn.svm import OneClassSVM
from sklearn.neighbors import LocalOutlierFactor
from sklearn.model_selection import ParameterGrid, TimeSeriesSplit
import time


class AnomalyDetectorPipeline:
    """Pipeline for training and comparing anomaly detection models."""
    
    MODEL_CONFIGS = {
        'IsolationForest': {
            'class': IsolationForest,
            'default_params': {
                'n_estimators': [100, 200, 300],
                'max_samples': ['auto', 0.5, 0.8],
                'contamination': [0.05, 0.10, 0.15],
                'max_features': [0.5, 0.8, 1.0],
                'random_state': [42]
            },
            'max_configs': 15
        },
        'OneClassSVM': {
            'class': OneClassSVM,
            'default_params': {
                'kernel': ['rbf', 'poly'],
                'nu': [0.05, 0.10, 0.15],
                'gamma': ['scale', 'auto', 0.1]
            },
            'max_configs': 9,
            'subsample': True
        },
        'LocalOutlierFactor': {
            'class': LocalOutlierFactor,
            'default_params': {
                'n_neighbors': [10, 20, 50],
                'contamination': [0.05, 0.10, 0.15],
                'metric': ['euclidean', 'manhattan']
            },
            'max_configs': 9,
            'subsample': True,
            'extra_kwargs': {'novelty': True}
        }
    }
    
    def __init__(self, evaluator=None):
        self.evaluator = evaluator
        self.results = {}
        self.best_models = {}
    
    def train_isolation_forest(
        self, 
        X_train: np.ndarray, 
        y_train: pd.Series,
        X_val: np.ndarray,
        y_val: pd.Series,
        param_grid: Optional[Dict] = None,
        max_configs: int = 15,
        n_cv_splits: int = 3
    ) -> List[Dict]:
        """Train Isolation Forest with hyperparameter tuning."""
        if param_grid is None:
            param_grid = self.MODEL_CONFIGS['IsolationForest']['default_params']
        
        results = []
        best_f1 = 0
        best_model = None
        best_params = None
        
        tscv = TimeSeriesSplit(n_splits=n_cv_splits)
        
        for i, params in enumerate(ParameterGrid(param_grid)):
            if i >= max_configs:
                break
            
            start_time = time.time()
            
            cv_scores = []
            for train_idx, test_idx in tscv.split(X_train):
                X_cv_train, X_cv_test = X_train[train_idx], X_train[test_idx]
                y_cv_train, y_cv_test = y_train.iloc[train_idx], y_train.iloc[test_idx]
                
                model = IsolationForest(**params)
                model.fit(X_cv_train)
                y_pred = model.predict(X_cv_test)
                y_scores = model.decision_function(X_cv_test)
                
                if self.evaluator:
                    metrics = self.evaluator.evaluate(y_cv_test, y_pred, y_scores)
                    cv_scores.append(metrics['f1_score'])
            
            avg_cv_f1 = np.mean(cv_scores) if cv_scores else 0
            
            final_model = IsolationForest(**params)
            final_model.fit(X_train)
            y_val_pred = final_model.predict(X_val)
            y_val_scores = final_model.decision_function(X_val)
            
            val_metrics = self.evaluator.evaluate(y_val, y_val_pred, y_val_scores) if self.evaluator else {}
            
            train_time = time.time() - start_time
            
            result = {
                'model_type': 'IsolationForest',
                'params': params,
                'cv_f1_mean': avg_cv_f1,
                'cv_f1_std': np.std(cv_scores) if cv_scores else 0,
                'val_precision': val_metrics.get('precision', 0),
                'val_recall': val_metrics.get('recall', 0),
                'val_f1': val_metrics.get('f1_score', 0),
                'val_roc_auc': val_metrics.get('roc_auc', 0),
                'train_time': train_time
            }
            results.append(result)
            
            if val_metrics.get('f1_score', 0) > best_f1:
                best_f1 = val_metrics['f1_score']
                best_model = final_model
                best_params = params
        
        self.results['IsolationForest'] = results
        self.best_models['IsolationForest'] = (best_model, best_params, best_f1)
        
        return results
    
    def train_one_class_svm(
        self,
        X_train: np.ndarray,
        y_train: pd.Series,
        X_val: np.ndarray,
        y_val: pd.Series,
        param_grid: Optional[Dict] = None,
        max_configs: int = 9,
        max_samples: int = 50000
    ) -> List[Dict]:
        """Train One-Class SVM with hyperparameter tuning."""
        if param_grid is None:
            param_grid = self.MODEL_CONFIGS['OneClassSVM']['default_params']
        
        X_train_subset = X_train[:max_samples] if len(X_train) > max_samples else X_train
        y_train_subset = y_train.iloc[:max_samples] if len(y_train) > max_samples else y_train
        X_val_subset = X_val[:20000] if len(X_val) > 20000 else X_val
        y_val_subset = y_val.iloc[:20000] if len(y_val) > 20000 else y_val
        
        results = []
        best_f1 = 0
        best_model = None
        best_params = None
        
        for i, params in enumerate(ParameterGrid(param_grid)):
            if i >= max_configs:
                break
            
            start_time = time.time()
            
            model = OneClassSVM(**params)
            model.fit(X_train_subset)
            y_val_pred = model.predict(X_val_subset)
            y_val_scores = model.decision_function(X_val_subset)
            
            val_metrics = self.evaluator.evaluate(y_val_subset, y_val_pred, y_val_scores) if self.evaluator else {}
            
            train_time = time.time() - start_time
            
            result = {
                'model_type': 'OneClassSVM',
                'params': params,
                'val_precision': val_metrics.get('precision', 0),
                'val_recall': val_metrics.get('recall', 0),
                'val_f1': val_metrics.get('f1_score', 0),
                'val_roc_auc': val_metrics.get('roc_auc', 0),
                'train_time': train_time
            }
            results.append(result)
            
            if val_metrics.get('f1_score', 0) > best_f1:
                best_f1 = val_metrics['f1_score']
                best_model = model
                best_params = params
        
        self.results['OneClassSVM'] = results
        self.best_models['OneClassSVM'] = (best_model, best_params, best_f1)
        
        return results
    
    def train_local_outlier_factor(
        self,
        X_train: np.ndarray,
        y_train: pd.Series,
        X_val: np.ndarray,
        y_val: pd.Series,
        param_grid: Optional[Dict] = None,
        max_configs: int = 9,
        max_samples: int = 50000
    ) -> List[Dict]:
        """Train Local Outlier Factor with hyperparameter tuning."""
        if param_grid is None:
            param_grid = self.MODEL_CONFIGS['LocalOutlierFactor']['default_params']
        
        X_train_subset = X_train[:max_samples] if len(X_train) > max_samples else X_train
        X_val_subset = X_val[:20000] if len(X_val) > 20000 else X_val
        y_val_subset = y_val.iloc[:20000] if len(y_val) > 20000 else y_val
        
        results = []
        best_f1 = 0
        best_model = None
        best_params = None
        
        for i, params in enumerate(ParameterGrid(param_grid)):
            if i >= max_configs:
                break
            
            start_time = time.time()
            
            model = LocalOutlierFactor(**params, novelty=True)
            model.fit(X_train_subset)
            y_val_pred = model.predict(X_val_subset)
            y_val_scores = model.decision_function(X_val_subset)
            
            val_metrics = self.evaluator.evaluate(y_val_subset, y_val_pred, y_val_scores) if self.evaluator else {}
            
            train_time = time.time() - start_time
            
            result = {
                'model_type': 'LocalOutlierFactor',
                'params': params,
                'val_precision': val_metrics.get('precision', 0),
                'val_recall': val_metrics.get('recall', 0),
                'val_f1': val_metrics.get('f1_score', 0),
                'val_roc_auc': val_metrics.get('roc_auc', 0),
                'train_time': train_time
            }
            results.append(result)
            
            if val_metrics.get('f1_score', 0) > best_f1:
                best_f1 = val_metrics['f1_score']
                best_model = model
                best_params = params
        
        self.results['LocalOutlierFactor'] = results
        self.best_models['LocalOutlierFactor'] = (best_model, best_params, best_f1)
        
        return results
    
    def train_all_models(
        self,
        X_train: np.ndarray,
        y_train: pd.Series,
        X_val: np.ndarray,
        y_val: pd.Series
    ) -> Dict[str, List[Dict]]:
        """Train all model types and return results."""
        self.train_isolation_forest(X_train, y_train, X_val, y_val)
        self.train_one_class_svm(X_train, y_train, X_val, y_val)
        self.train_local_outlier_factor(X_train, y_train, X_val, y_val)
        return self.results
    
    def get_best_overall_model(self) -> Tuple[Any, str, Dict, float]:
        """Get the best model across all types."""
        best_f1 = 0
        best_model = None
        best_name = None
        best_params = None
        
        for model_name, (model, params, f1) in self.best_models.items():
            if model is not None and f1 > best_f1:
                best_f1 = f1
                best_model = model
                best_name = model_name
                best_params = params
        
        return best_model, best_name, best_params, best_f1
    
    def get_results_summary(self) -> pd.DataFrame:
        """Get summary DataFrame of all results."""
        all_results = []
        for model_type, results in self.results.items():
            all_results.extend(results)
        return pd.DataFrame(all_results)
