"""Machine Learning-based anomaly matching for ILI data.

Trains a RandomForest classifier on matched/unmatched pairs to predict
match probability with higher accuracy than rule-based matching.
"""

from __future__ import annotations

import math
import pickle
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

_MODEL_PATH = Path(__file__).parent / "ili_ml_match_model.pkl"


def extract_features(row1: dict, row2: dict, corr_dist2: float) -> list[float]:
    """Extract features for ML matching from two anomaly records.
    
    Args:
        row1: Anomaly from earlier run (dict with keys: log_dist_ft, depth_pct, length_in, width_in, oclock_decimal, joint_number)
        row2: Anomaly from later run
        corr_dist2: Corrected distance for row2 after odometer correction
        
    Returns:
        Feature vector: [dist_diff, clock_diff, depth_ratio, length_ratio, width_ratio, joint_diff]
    """
    dist1 = row1.get("log_dist_ft", 0)
    dist_diff = abs(corr_dist2 - dist1)
    
    clock1 = row1.get("oclock_decimal")
    clock2 = row2.get("oclock_decimal")
    if clock1 is not None and clock2 is not None:
        clock_diff_raw = abs(clock1 - clock2) % 12.0
        clock_diff = min(clock_diff_raw, 12.0 - clock_diff_raw)
    else:
        clock_diff = 6.0  # Worst case
    
    depth1 = row1.get("depth_pct", 1.0)
    depth2 = row2.get("depth_pct", 1.0)
    depth_ratio = (depth2 / depth1) if (depth1 and depth1 > 0) else 1.0
    
    len1 = row1.get("length_in", 1.0)
    len2 = row2.get("length_in", 1.0)
    length_ratio = (len2 / len1) if (len1 and len1 > 0) else 1.0
    
    wid1 = row1.get("width_in", 1.0)
    wid2 = row2.get("width_in", 1.0)
    width_ratio = (wid2 / wid1) if (wid1 and wid1 > 0) else 1.0
    
    joint1 = row1.get("joint_number", 0)
    joint2 = row2.get("joint_number", 0)
    joint_diff = abs(joint2 - joint1) if (joint1 and joint2) else 5
    
    return [dist_diff, clock_diff, depth_ratio, length_ratio, width_ratio, joint_diff]


def load_model() -> RandomForestClassifier | None:
    """Load trained ML matching model from disk."""
    if _MODEL_PATH.exists():
        with open(_MODEL_PATH, "rb") as f:
            return pickle.load(f)
    return None


def save_model(model: RandomForestClassifier):
    """Save trained ML matching model to disk."""
    with open(_MODEL_PATH, "wb") as f:
        pickle.dump(model, f)


def predict_match_probability(row1: dict, row2: dict, corr_dist2: float, model: RandomForestClassifier | None = None) -> float:
    """Predict match probability using ML model.
    
    Args:
        row1: Anomaly from earlier run
        row2: Anomaly from later run
        corr_dist2: Corrected distance for row2
        model: Trained RandomForestClassifier (loads from disk if None)
        
    Returns:
        Match probability (0-1)
    """
    if model is None:
        model = load_model()
    if model is None:
        # Fallback: return 0.5 if no model available
        return 0.5
    
    features = extract_features(row1, row2, corr_dist2)
    X = np.array([features])
    proba = model.predict_proba(X)[0][1]  # Probability of match (class 1)
    return float(proba)


def map_confidence(probability: float) -> str:
    """Map match probability to confidence level."""
    if probability > 0.8:
        return "high"
    elif probability > 0.5:
        return "medium"
    elif probability > 0.3:
        return "low"
    else:
        return "uncertain"
