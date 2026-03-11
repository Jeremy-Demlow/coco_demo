"""Model evaluation utilities."""

import numpy as np
import pandas as pd
from typing import Dict, Optional
from sklearn.metrics import precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix
import matplotlib.pyplot as plt


class ModelEvaluator:
    """Handles model evaluation and metrics calculation."""
    
    def evaluate(self, y_true, y_pred, y_scores=None) -> Dict:
        """Calculate evaluation metrics for anomaly detection."""
        y_pred_binary = (y_pred == -1).astype(int)
        
        metrics = {
            'precision': precision_score(y_true, y_pred_binary, zero_division=0),
            'recall': recall_score(y_true, y_pred_binary, zero_division=0),
            'f1_score': f1_score(y_true, y_pred_binary, zero_division=0),
        }
        
        if y_scores is not None:
            try:
                metrics['roc_auc'] = roc_auc_score(y_true, -y_scores)
            except:
                metrics['roc_auc'] = 0.0
        
        cm = confusion_matrix(y_true, y_pred_binary)
        metrics['true_negatives'] = cm[0, 0] if cm.shape[0] > 1 else 0
        metrics['false_positives'] = cm[0, 1] if cm.shape[1] > 1 else 0
        metrics['false_negatives'] = cm[1, 0] if cm.shape[0] > 1 else 0
        metrics['true_positives'] = cm[1, 1] if cm.shape == (2, 2) else 0
        
        return metrics
    
    def plot_model_comparison(self, results_df: pd.DataFrame, save_path: Optional[str] = None):
        """Create comparison plots for model results."""
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        
        ax1 = axes[0, 0]
        for model_type in results_df['model_type'].unique():
            model_data = results_df[results_df['model_type'] == model_type]
            ax1.scatter(model_data['val_precision'], model_data['val_recall'], 
                       label=model_type, s=100, alpha=0.7)
        ax1.set_xlabel('Precision')
        ax1.set_ylabel('Recall')
        ax1.set_title('Precision vs Recall by Model Type')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        ax2 = axes[0, 1]
        best_f1_by_model = results_df.loc[results_df.groupby('model_type')['val_f1'].idxmax()]
        colors = ['steelblue', 'coral', 'green'][:len(best_f1_by_model)]
        ax2.bar(best_f1_by_model['model_type'], best_f1_by_model['val_f1'], color=colors)
        ax2.set_xlabel('Model Type')
        ax2.set_ylabel('Best F1 Score')
        ax2.set_title('Best F1 Score by Model Type')
        ax2.tick_params(axis='x', rotation=45)
        
        ax3 = axes[1, 0]
        ax3.boxplot([results_df[results_df['model_type'] == m]['val_f1'] 
                    for m in results_df['model_type'].unique()],
                   labels=results_df['model_type'].unique())
        ax3.set_ylabel('F1 Score')
        ax3.set_title('F1 Score Distribution by Model')
        ax3.tick_params(axis='x', rotation=45)
        
        ax4 = axes[1, 1]
        metrics = ['val_precision', 'val_recall', 'val_f1', 'val_roc_auc']
        x = np.arange(len(metrics))
        width = 0.25
        for i, model_type in enumerate(best_f1_by_model['model_type'].unique()):
            model_row = best_f1_by_model[best_f1_by_model['model_type'] == model_type].iloc[0]
            values = [model_row[m] for m in metrics]
            ax4.bar(x + i*width, values, width, label=model_type)
        ax4.set_xlabel('Metric')
        ax4.set_ylabel('Score')
        ax4.set_title('Best Model Metrics Comparison')
        ax4.set_xticks(x + width)
        ax4.set_xticklabels(['Precision', 'Recall', 'F1', 'ROC-AUC'])
        ax4.legend()
        
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
    
    def plot_score_distribution(self, model, X_val, y_val, save_path: Optional[str] = None):
        """Plot anomaly score distribution for normal vs anomaly classes."""
        y_scores = model.decision_function(X_val)
        
        fig, ax = plt.subplots(figsize=(10, 6))
        ax.hist(y_scores[y_val == 0], bins=50, alpha=0.7, label='Normal', density=True)
        ax.hist(y_scores[y_val == 1], bins=50, alpha=0.7, label='Anomaly', density=True)
        ax.set_xlabel('Anomaly Score')
        ax.set_ylabel('Density')
        ax.set_title('Score Distribution: Normal vs Anomaly')
        ax.legend()
        
        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
        
        return fig
