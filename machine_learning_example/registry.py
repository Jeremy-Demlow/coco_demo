"""Model registry and deployment utilities."""

import pandas as pd
from typing import Dict, Any, Optional, List


class ModelRegistryManager:
    """Manages model registration, versioning, and deployment."""
    
    def __init__(self, session, database: str = "COCO_LIVE_DB", schema: str = "DBT"):
        self.session = session
        self.database = database
        self.schema = schema
        self._registry = None
        self._experiment = None
    
    @property
    def registry(self):
        if self._registry is None:
            from snowflake.ml.registry import Registry
            self._registry = Registry(
                session=self.session,
                database_name=self.database,
                schema_name=self.schema
            )
        return self._registry
    
    def create_experiment(self, name: str):
        """Create or get an experiment for tracking."""
        from snowflake.ml.experiment import Experiment
        self._experiment = Experiment(
            session=self.session,
            name=name,
            database=self.database,
            schema=self.schema
        )
        return self._experiment
    
    def log_experiment_run(
        self,
        model_name: str,
        params: Dict,
        metrics: Dict,
        model: Any
    ):
        """Log a model training run to the experiment."""
        if self._experiment is None:
            raise ValueError("No experiment created. Call create_experiment first.")
        
        run = self._experiment.start_run(run_name=f"{model_name}_best")
        
        run.log_param("model_type", model_name)
        for param_name, param_value in params.items():
            run.log_param(param_name, str(param_value))
        
        for metric_name, metric_value in metrics.items():
            run.log_metric(metric_name, metric_value)
        
        run.end_run()
        return run
    
    def register_model(
        self,
        model: Any,
        model_name: str,
        version: str,
        sample_input: pd.DataFrame,
        metrics: Dict,
        feature_columns: List[str],
        comment: str = ""
    ):
        """Register a model to the Snowflake Model Registry."""
        registry_name = f"ANOMALY_DETECTOR_{model_name.upper()}"
        
        model_info = self.registry.log_model(
            model=model,
            model_name=registry_name,
            version_name=version,
            sample_input_data=sample_input,
            metrics=metrics,
            comment=comment
        )
        
        return model_info, registry_name
    
    def register_all_models(
        self,
        best_models: Dict,
        X_train_scaled,
        feature_columns: List[str],
        version: str = "v1"
    ) -> Dict:
        """Register all best models to the registry."""
        model_versions = {}
        
        for model_name, (model, params, f1) in best_models.items():
            if model is None:
                continue
            
            sample_input = pd.DataFrame(X_train_scaled[:5], columns=feature_columns)
            
            model_info, registry_name = self.register_model(
                model=model,
                model_name=model_name,
                version=version,
                sample_input=sample_input,
                metrics={
                    "f1_score": float(f1),
                    "model_type": model_name
                },
                feature_columns=feature_columns,
                comment=f"{model_name} anomaly detector for reconciliation variances. Params: {params}"
            )
            
            model_versions[model_name] = {
                'model_info': model_info,
                'registry_name': registry_name,
                'f1_score': f1
            }
        
        return model_versions
    
    def promote_model(self, model_name: str, version: str = "v1"):
        """Promote a model version to be the default."""
        model_ref = self.registry.get_model(model_name)
        model_ref.default = version
        return model_ref
    
    def get_best_registered_model(self, model_versions: Dict) -> Dict:
        """Get the best model from registered models."""
        sorted_models = sorted(
            model_versions.items(),
            key=lambda x: x[1]['f1_score'],
            reverse=True
        )
        return sorted_models[0] if sorted_models else None
    
    def deploy_for_inference(self, model_name: str) -> str:
        """Generate SQL for model inference."""
        return f"""
-- Real-time inference using the registered model
WITH features AS (
    SELECT *
    FROM {self.database}.{self.schema}.ANOMALY_DETECTION_FEATURES
    WHERE period_end_date = (SELECT MAX(period_end_date) FROM {self.database}.{self.schema}.ANOMALY_DETECTION_FEATURES)
)
SELECT 
    assignment_id,
    period_end_date,
    entity_name,
    account_combination,
    variance_amount,
    {self.database}.{self.schema}.{model_name}!PREDICT(*) as anomaly_prediction
FROM features
ORDER BY anomaly_prediction DESC
"""
    
    def create_inference_udf(self, model_name: str, registry_name: str):
        """Create a UDF for model inference."""
        sql = f"""
CREATE OR REPLACE FUNCTION {self.database}.{self.schema}.predict_anomaly(
    variance_amount FLOAT,
    gl_bank_diff FLOAT,
    variance_z_score FLOAT
)
RETURNS FLOAT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-ml-python')
HANDLER = 'predict'
AS
$$
from snowflake.ml.registry import Registry

def predict(variance_amount, gl_bank_diff, variance_z_score):
    # This is a simplified example - actual implementation would use full feature set
    return 0.0  # Placeholder
$$
"""
        return sql
