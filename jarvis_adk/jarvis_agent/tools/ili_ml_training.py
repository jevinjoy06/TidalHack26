"""Train ML matching model on ILI data.

Generates positive (matched) and negative (non-matched) examples from
existing alignment data, trains a RandomForest classifier, and saves it.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

from .ili_processing import get_dataset, reset_dataset
from .ili_ml_matching import extract_features, save_model

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
ILIData_PATH = PROJECT_ROOT / "ILIDataV2.xlsx"


def train_matching_model(test_size: float = 0.2, random_state: int = 42) -> dict:
    """Train ML matching model on existing ILI data.
    
    Args:
        test_size: Fraction of data for testing
        random_state: Random seed
        
    Returns:
        Training results: {accuracy, precision, recall, model_path}
    """
    reset_dataset()
    ds = get_dataset()
    ds.load(str(ILIData_PATH))
    ds.align_welds()
    ds.match_anomalies()
    
    X = []
    y = []
    
    # Generate positive examples from matches
    for (y1, y2), matches_df in ds.matches.items():
        ml1 = ds.anomalies[y1]
        ml2 = ds.anomalies[y2]
        
        corr_func = ds.correction_funcs.get((y1, y2))
        if corr_func is None:
            continue
        
        for _, match in matches_df.iterrows():
            idx1 = match["y1_idx"]
            idx2 = match["y2_idx"]
            
            row1 = ml1.loc[idx1].to_dict()
            row2 = ml2.loc[idx2].to_dict()
            corr_dist2 = match["y2_corrected_dist"]
            
            features = extract_features(row1, row2, corr_dist2)
            X.append(features)
            y.append(1)  # Match
        
        # Generate negative examples (non-matches)
        # For each matched y2, sample a few y1 anomalies that are NOT the match
        for _, match in matches_df.head(min(len(matches_df), 100)).iterrows():
            idx2 = match["y2_idx"]
            row2 = ml2.loc[idx2].to_dict()
            corr_dist2 = match["y2_corrected_dist"]
            
            # Sample 2 random non-matches from y1
            other_y1 = ml1[~ml1.index.isin(matches_df["y1_idx"])]
            if len(other_y1) > 0:
                samples = other_y1.sample(min(2, len(other_y1)), random_state=random_state)
                for _, row1 in samples.iterrows():
                    features = extract_features(row1.to_dict(), row2, corr_dist2)
                    X.append(features)
                    y.append(0)  # Non-match
    
    if len(X) < 10:
        return {"error": "Not enough training examples"}
    
    X = np.array(X)
    y = np.array(y)
    
    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=test_size, random_state=random_state)
    
    # Train RandomForest
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=random_state, n_jobs=-1)
    model.fit(X_train, y_train)
    
    # Evaluate
    train_acc = model.score(X_train, y_train)
    test_acc = model.score(X_test, y_test)
    
    # Precision/Recall on test set
    from sklearn.metrics import precision_score, recall_score
    y_pred = model.predict(X_test)
    precision = precision_score(y_test, y_pred, zero_division=0)
    recall = recall_score(y_test, y_pred, zero_division=0)
    
    # Save model
    save_model(model)
    
    return {
        "samples": len(X),
        "positive": int(y.sum()),
        "negative": int((y == 0).sum()),
        "train_accuracy": round(train_acc, 3),
        "test_accuracy": round(test_acc, 3),
        "precision": round(precision, 3),
        "recall": round(recall, 3),
        "model_path": str(Path(__file__).parent / "ili_ml_match_model.pkl"),
    }


if __name__ == "__main__":
    print("Training ML matching model on ILIDataV2.xlsx...")
    result = train_matching_model()
    print("Training complete:")
    for k, v in result.items():
        print(f"  {k}: {v}")
