"""Feature engineering using Snowflake Feature Store API."""

import pandas as pd
import numpy as np
from typing import List, Tuple, Optional
from snowflake.ml.feature_store import FeatureStore, FeatureView, Entity, CreationMode


FEATURE_COLUMNS = [
    'VARIANCE_AMOUNT', 'GL_BANK_DIFF', 'GL_SUBLEDGER_DIFF', 'RECON_COUNT', 'UNIDENTIFIED_AMOUNT',
    'VARIANCE_PCT_CHANGE', 'VARIANCE_Z_SCORE', 'VARIANCE_Z_SCORE_PERIOD', 'VARIANCE_PCT_OF_BALANCE',
    'VARIANCE_VS_ROLLING_MAX', 'IS_ABOVE_P95', 'GL_BANK_DIFF_RATIO', 'BALANCE_CHANGE_PCT',
    'HIERARCHY_DEPTH_NORMALIZED', 'IS_KEY_ACCOUNT_FLAG', 'ROLLING_AVG_VARIANCE_3', 'ROLLING_STD_VARIANCE_3',
    'ROLLING_MAX_VARIANCE_6', 'ENTITY_AVG_VARIANCE', 'ENTITY_ASSIGNMENT_COUNT'
]


class FeatureEngineer:
    """Handles feature engineering using Snowflake Feature Store."""
    
    def __init__(self, session, database: str, schema: str, warehouse: str):
        self.session = session
        self.database = database
        self.schema = schema
        self.warehouse = warehouse
        self.feature_store = None
        self.feature_columns = FEATURE_COLUMNS
    
    def create_feature_store(self, creation_mode: CreationMode = CreationMode.CREATE_IF_NOT_EXIST) -> FeatureStore:
        """Create or connect to the Snowflake Feature Store."""
        self.feature_store = FeatureStore(
            session=self.session,
            database=self.database,
            name=self.schema,
            default_warehouse=self.warehouse,
            creation_mode=creation_mode
        )
        return self.feature_store
    
    def register_entity(self, name: str, join_keys: List[str], desc: str = "") -> Entity:
        """Register an entity in the feature store."""
        entity = Entity(
            name=name,
            join_keys=join_keys,
            desc=desc
        )
        self.feature_store.register_entity(entity)
        return entity
    
    def create_reconciliation_entity(self) -> Entity:
        """Create the reconciliation assignment entity."""
        return self.register_entity(
            name="RECONCILIATION_ASSIGNMENT",
            join_keys=["ASSIGNMENT_ID", "PERIOD_ID"],
            desc="Unique reconciliation assignment for each period"
        )
    
    def build_feature_dataframe(self, source_table: str):
        """Build the feature transformation DataFrame using Snowpark."""
        from snowflake.snowpark.functions import col, lag, avg, stddev, max as sf_max, count, when, lit, abs as sf_abs
        from snowflake.snowpark.window import Window
        
        base = self.session.table(source_table).filter(col("IS_ACTIVE") == True)
        
        assignment_window = Window.partition_by("ASSIGNMENT_ID").order_by("PERIOD_END_DATE")
        entity_window = Window.partition_by("ENTITY_ID")
        rolling_window_3 = Window.partition_by("ASSIGNMENT_ID").order_by("PERIOD_END_DATE").rows_between(-3, -1)
        rolling_window_6 = Window.partition_by("ASSIGNMENT_ID").order_by("PERIOD_END_DATE").rows_between(-6, -1)
        
        features_df = base.select(
            col("ASSIGNMENT_ID"),
            col("PERIOD_ID"),
            col("PERIOD_END_DATE"),
            col("ENTITY_ID"),
            col("ENTITY_NAME"),
            col("ACCOUNT_COMBINATION"),
            col("RECONCILIATION_STATUS"),
            col("IS_KEY_ACCOUNT"),
            col("HIERARCHY_DEPTH"),
            col("BALANCE_GL"),
            col("TOTAL_ABS_VARIANCE").alias("VARIANCE_AMOUNT"),
            col("GL_BANK_DIFFERENCE").alias("GL_BANK_DIFF"),
            col("GL_SUBLEDGER_DIFFERENCE").alias("GL_SUBLEDGER_DIFF"),
            col("RECONCILIATION_COUNT").alias("RECON_COUNT"),
            col("TOTAL_UNIDENTIFIED_AMOUNT").alias("UNIDENTIFIED_AMOUNT")
        )
        
        features_df = features_df.with_column(
            "PREV_VARIANCE",
            lag("VARIANCE_AMOUNT", 1).over(assignment_window)
        ).with_column(
            "PREV_BALANCE_GL",
            lag("BALANCE_GL", 1).over(assignment_window)
        ).with_column(
            "ROLLING_AVG_VARIANCE_3",
            avg("VARIANCE_AMOUNT").over(rolling_window_3)
        ).with_column(
            "ROLLING_STD_VARIANCE_3",
            stddev("VARIANCE_AMOUNT").over(rolling_window_3)
        ).with_column(
            "ROLLING_MAX_VARIANCE_6",
            sf_max("VARIANCE_AMOUNT").over(rolling_window_6)
        ).with_column(
            "ENTITY_AVG_VARIANCE",
            avg("VARIANCE_AMOUNT").over(entity_window)
        ).with_column(
            "ENTITY_ASSIGNMENT_COUNT",
            count("*").over(entity_window)
        )
        
        features_df = features_df.with_column(
            "VARIANCE_PCT_CHANGE",
            when(col("PREV_VARIANCE").is_null() | (col("PREV_VARIANCE") == 0), lit(0))
            .otherwise((col("VARIANCE_AMOUNT") - col("PREV_VARIANCE")) / col("PREV_VARIANCE"))
        ).with_column(
            "VARIANCE_Z_SCORE",
            when(col("ROLLING_STD_VARIANCE_3").is_null() | (col("ROLLING_STD_VARIANCE_3") == 0), lit(0))
            .otherwise((col("VARIANCE_AMOUNT") - col("ROLLING_AVG_VARIANCE_3")) / col("ROLLING_STD_VARIANCE_3"))
        ).with_column(
            "VARIANCE_Z_SCORE_PERIOD",
            lit(0)
        ).with_column(
            "VARIANCE_PCT_OF_BALANCE",
            when(col("BALANCE_GL") == 0, lit(0))
            .otherwise(col("VARIANCE_AMOUNT") / sf_abs(col("BALANCE_GL")))
        ).with_column(
            "VARIANCE_VS_ROLLING_MAX",
            when(col("ROLLING_MAX_VARIANCE_6").is_null() | (col("ROLLING_MAX_VARIANCE_6") == 0), lit(0))
            .otherwise(col("VARIANCE_AMOUNT") / col("ROLLING_MAX_VARIANCE_6"))
        ).with_column(
            "IS_ABOVE_P95",
            lit(0)
        ).with_column(
            "GL_BANK_DIFF_RATIO",
            when(col("BALANCE_GL") == 0, lit(0))
            .otherwise(col("GL_BANK_DIFF") / sf_abs(col("BALANCE_GL")))
        ).with_column(
            "BALANCE_CHANGE_PCT",
            when(col("PREV_BALANCE_GL").is_null() | (col("PREV_BALANCE_GL") == 0), lit(0))
            .otherwise((col("BALANCE_GL") - col("PREV_BALANCE_GL")) / sf_abs(col("PREV_BALANCE_GL")))
        ).with_column(
            "HIERARCHY_DEPTH_NORMALIZED",
            col("HIERARCHY_DEPTH") / 10.0
        ).with_column(
            "IS_KEY_ACCOUNT_FLAG",
            when(col("IS_KEY_ACCOUNT") == True, lit(1)).otherwise(lit(0))
        ).with_column(
            "IS_ANOMALY_LABEL",
            when(
                (col("RECONCILIATION_STATUS") == "High Variance") | 
                (col("VARIANCE_Z_SCORE") > 3) |
                (col("VARIANCE_Z_SCORE") < -3),
                lit(1)
            ).otherwise(lit(0))
        )
        
        final_columns = [
            "ASSIGNMENT_ID", "PERIOD_ID", "PERIOD_END_DATE", "ENTITY_ID", "ENTITY_NAME",
            "ACCOUNT_COMBINATION", "RECONCILIATION_STATUS"
        ] + self.feature_columns + ["IS_ANOMALY_LABEL"]
        
        return features_df.select(*final_columns)
    
    def create_feature_view(
        self,
        name: str,
        entity: Entity,
        source_table: str,
        refresh_freq: str = "1 hour",
        desc: str = ""
    ) -> FeatureView:
        """Create a Snowflake-managed feature view with automatic refresh."""
        feature_df = self.build_feature_dataframe(source_table)
        
        fv = FeatureView(
            name=name,
            entities=[entity],
            feature_df=feature_df,
            timestamp_col="PERIOD_END_DATE",
            refresh_freq=refresh_freq,
            desc=desc
        )
        
        fv = fv.attach_feature_desc({
            "VARIANCE_AMOUNT": "Total absolute variance amount for reconciliation",
            "GL_BANK_DIFF": "Difference between GL and bank balances",
            "VARIANCE_Z_SCORE": "Z-score of variance relative to rolling average",
            "VARIANCE_PCT_CHANGE": "Percent change in variance from previous period",
            "IS_ANOMALY_LABEL": "Binary label indicating anomaly (1) or normal (0)"
        })
        
        return fv
    
    def create_external_feature_view(
        self,
        name: str,
        entity: Entity,
        feature_table: str,
        desc: str = ""
    ) -> FeatureView:
        """Create an external feature view backed by user-managed table (e.g., dbt)."""
        feature_df = self.session.table(feature_table)
        
        fv = FeatureView(
            name=name,
            entities=[entity],
            feature_df=feature_df,
            timestamp_col="PERIOD_END_DATE",
            refresh_freq=None,
            desc=desc
        )
        
        return fv
    
    def register_feature_view(self, feature_view: FeatureView, version: str, overwrite: bool = False) -> FeatureView:
        """Register a feature view in the feature store."""
        return self.feature_store.register_feature_view(
            feature_view=feature_view,
            version=version,
            block=True,
            overwrite=overwrite
        )
    
    def get_feature_view(self, name: str, version: str) -> FeatureView:
        """Retrieve a registered feature view."""
        return self.feature_store.get_feature_view(name=name, version=version)
    
    def list_feature_views(self, entity_name: Optional[str] = None):
        """List all feature views, optionally filtered by entity."""
        return self.feature_store.list_feature_views(entity_name=entity_name)
    
    def generate_training_data(
        self,
        feature_views: List[FeatureView],
        spine_df,
        timestamp_col: str = "PERIOD_END_DATE",
        include_feature_view_timestamp_col: bool = False
    ):
        """Generate point-in-time correct training data from feature views."""
        return self.feature_store.generate_dataset(
            name="anomaly_detection_training",
            spine_df=spine_df,
            features=feature_views,
            spine_timestamp_col=timestamp_col,
            include_feature_view_timestamp_col=include_feature_view_timestamp_col
        )
    
    def retrieve_features(
        self,
        feature_view: FeatureView,
        spine_df = None,
        split_date: Optional[str] = None
    ) -> Tuple[pd.DataFrame, pd.DataFrame]:
        """Retrieve features from feature view with optional temporal split."""
        from snowflake.snowpark.functions import col
        
        if spine_df is not None:
            features_df = self.feature_store.retrieve_feature_values(
                spine_df=spine_df,
                features=[feature_view],
                spine_timestamp_col="PERIOD_END_DATE"
            )
        else:
            features_df = self.feature_store.read_feature_view(feature_view)
        
        if split_date:
            train_df = features_df.filter(col("PERIOD_END_DATE") < split_date).to_pandas()
            val_df = features_df.filter(col("PERIOD_END_DATE") >= split_date).to_pandas()
            return train_df, val_df
        else:
            return features_df.to_pandas(), pd.DataFrame()
    
    def get_temporal_split_date(self, source_table: str, train_ratio: float = 0.8) -> str:
        """Calculate the split date for temporal train/validation split."""
        periods_df = self.session.sql(f"""
            SELECT DISTINCT PERIOD_END_DATE 
            FROM {source_table}
            WHERE IS_ACTIVE = TRUE
            ORDER BY PERIOD_END_DATE
        """).to_pandas()
        
        num_periods = len(periods_df)
        split_idx = int(num_periods * train_ratio)
        return str(periods_df.iloc[split_idx]['PERIOD_END_DATE'])
    
    def prepare_training_data(self, train_df: pd.DataFrame, val_df: pd.DataFrame) -> Tuple:
        """Prepare data for model training with scaling."""
        from sklearn.preprocessing import StandardScaler
        
        X_train = train_df[self.feature_columns].fillna(0).replace([np.inf, -np.inf], 0)
        y_train = train_df['IS_ANOMALY_LABEL']
        
        X_val = val_df[self.feature_columns].fillna(0).replace([np.inf, -np.inf], 0)
        y_val = val_df['IS_ANOMALY_LABEL']
        
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_val_scaled = scaler.transform(X_val)
        
        return X_train_scaled, y_train, X_val_scaled, y_val, scaler
