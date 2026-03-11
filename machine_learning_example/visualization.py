"""Visualization utilities for EDA and model analysis."""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from typing import Optional, List, Tuple


class EDAVisualizer:
    """Visualization utilities for exploratory data analysis."""
    
    @staticmethod
    def plot_status_distribution(status_df: pd.DataFrame, save_path: Optional[str] = None):
        """Plot reconciliation status distribution."""
        fig, axes = plt.subplots(1, 2, figsize=(14, 5))
        
        ax1 = axes[0]
        status_df.plot(kind='bar', x='RECONCILIATION_STATUS', y='COUNT', 
                      ax=ax1, color='steelblue', legend=False)
        ax1.set_title('Reconciliation Status Distribution', fontsize=12)
        ax1.set_xlabel('Status')
        ax1.set_ylabel('Count')
        ax1.tick_params(axis='x', rotation=45)
        
        ax2 = axes[1]
        status_df.plot(kind='bar', x='RECONCILIATION_STATUS', y='AVG_VARIANCE', 
                      ax=ax2, color='coral', legend=False)
        ax2.set_title('Average Variance by Status', fontsize=12)
        ax2.set_xlabel('Status')
        ax2.set_ylabel('Avg Variance ($)')
        ax2.tick_params(axis='x', rotation=45)
        
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
    
    @staticmethod
    def plot_variance_trends(variance_df: pd.DataFrame, save_path: Optional[str] = None):
        """Plot variance trends over time."""
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        
        ax1 = axes[0, 0]
        ax1.plot(variance_df['PERIOD_END_DATE'], variance_df['AVG_VARIANCE'], 
                marker='o', color='steelblue')
        if 'STDDEV_VARIANCE' in variance_df.columns:
            ax1.fill_between(
                variance_df['PERIOD_END_DATE'],
                variance_df['AVG_VARIANCE'] - variance_df['STDDEV_VARIANCE'],
                variance_df['AVG_VARIANCE'] + variance_df['STDDEV_VARIANCE'],
                alpha=0.3
            )
        ax1.set_title('Average Variance Over Time (with Std Dev)', fontsize=12)
        ax1.set_xlabel('Period')
        ax1.set_ylabel('Variance ($)')
        ax1.tick_params(axis='x', rotation=45)
        
        ax2 = axes[0, 1]
        ax2.bar(variance_df['PERIOD_END_DATE'], variance_df['HIGH_VARIANCE_COUNT'], color='coral')
        ax2.set_title('High Variance Count by Period', fontsize=12)
        ax2.set_xlabel('Period')
        ax2.set_ylabel('Count')
        ax2.tick_params(axis='x', rotation=45)
        
        ax3 = axes[1, 0]
        ax3.plot(variance_df['PERIOD_END_DATE'], variance_df['P95_VARIANCE'], 
                marker='s', color='green')
        ax3.set_title('95th Percentile Variance Trend', fontsize=12)
        ax3.set_xlabel('Period')
        ax3.set_ylabel('P95 Variance ($)')
        ax3.tick_params(axis='x', rotation=45)
        
        ax4 = axes[1, 1]
        scatter = ax4.scatter(
            variance_df['TOTAL_RECORDS'], 
            variance_df['AVG_VARIANCE'],
            c=variance_df['PERIOD_YEAR'] if 'PERIOD_YEAR' in variance_df.columns else 'steelblue',
            cmap='viridis', 
            s=100
        )
        ax4.set_title('Variance vs Record Count (colored by year)', fontsize=12)
        ax4.set_xlabel('Total Records')
        ax4.set_ylabel('Avg Variance ($)')
        
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
    
    @staticmethod
    def plot_variance_distribution(buckets_df: pd.DataFrame, save_path: Optional[str] = None):
        """Plot variance bucket distribution."""
        fig, ax = plt.subplots(figsize=(10, 6))
        buckets_df.plot(kind='bar', x='VARIANCE_BUCKET', y='COUNT', 
                       ax=ax, color='steelblue', logy=True)
        ax.set_title('Variance Distribution (Log Scale)', fontsize=12)
        ax.set_xlabel('Variance Bucket')
        ax.set_ylabel('Count (Log Scale)')
        ax.tick_params(axis='x', rotation=45)
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
    
    @staticmethod
    def plot_correlation_matrix(df: pd.DataFrame, feature_columns: List[str], 
                               save_path: Optional[str] = None):
        """Plot feature correlation matrix."""
        corr_matrix = df[feature_columns].corr()
        
        fig, ax = plt.subplots(figsize=(12, 10))
        sns.heatmap(corr_matrix, annot=False, cmap='coolwarm', center=0, ax=ax)
        ax.set_title('Feature Correlation Matrix', fontsize=14)
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
    
    @staticmethod
    def plot_feature_importance(X_train_scaled: np.ndarray, feature_columns: List[str],
                               top_n: int = 10, save_path: Optional[str] = None):
        """Plot top feature importance based on mean absolute values."""
        feature_importance = np.abs(X_train_scaled).mean(axis=0)
        top_features_idx = np.argsort(feature_importance)[-top_n:]
        top_features = [feature_columns[i] for i in top_features_idx]
        top_importance = feature_importance[top_features_idx]
        
        fig, ax = plt.subplots(figsize=(10, 6))
        ax.barh(top_features, top_importance, color='steelblue')
        ax.set_xlabel('Mean Absolute Value')
        ax.set_title(f'Top {top_n} Features by Mean Absolute Value')
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
    
    @staticmethod
    def create_final_report(
        status_df: pd.DataFrame,
        results_df: pd.DataFrame,
        best_models: List[dict],
        best_model,
        X_val,
        y_val,
        save_path: Optional[str] = None
    ):
        """Create comprehensive final report visualization."""
        fig, axes = plt.subplots(2, 3, figsize=(16, 10))
        
        ax1 = axes[0, 0]
        status_df.plot(kind='pie', y='COUNT', labels=status_df['RECONCILIATION_STATUS'], 
                      ax=ax1, autopct='%1.1f%%')
        ax1.set_title('Reconciliation Status Distribution')
        ax1.set_ylabel('')
        
        ax2 = axes[0, 1]
        for model_type in results_df['model_type'].unique():
            model_data = results_df[results_df['model_type'] == model_type]
            ax2.scatter(model_data['val_precision'], model_data['val_recall'], 
                       label=model_type, s=80, alpha=0.7)
        ax2.set_xlabel('Precision')
        ax2.set_ylabel('Recall')
        ax2.set_title('Model Performance: Precision vs Recall')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        ax3 = axes[0, 2]
        model_names = [m['registry_name'].replace('ANOMALY_DETECTOR_', '') for m in best_models]
        f1_scores = [m['f1_score'] for m in best_models]
        colors = ['gold' if i == 0 else 'steelblue' for i in range(len(model_names))]
        ax3.barh(model_names, f1_scores, color=colors)
        ax3.set_xlabel('F1 Score')
        ax3.set_title('Final Model Comparison')
        
        ax4 = axes[1, 0]
        if best_model is not None:
            y_scores_final = best_model.decision_function(X_val)
            ax4.hist(y_scores_final[y_val == 0], bins=50, alpha=0.7, 
                    label='Normal', density=True)
            ax4.hist(y_scores_final[y_val == 1], bins=50, alpha=0.7, 
                    label='Anomaly', density=True)
            ax4.set_xlabel('Anomaly Score')
            ax4.set_ylabel('Density')
            ax4.set_title('Score Distribution (Best Model)')
            ax4.legend()
        
        axes[1, 1].axis('off')
        axes[1, 2].axis('off')
        
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
