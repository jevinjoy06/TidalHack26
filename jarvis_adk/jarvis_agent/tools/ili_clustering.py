"""Spatial clustering of anomalies for interaction analysis.

Uses DBSCAN to identify clusters of closely-spaced anomalies that may
interact and affect pipeline integrity.
"""

from __future__ import annotations

import math
from typing import Any

import numpy as np
import pandas as pd
from sklearn.cluster import DBSCAN


def cluster_anomalies(anomalies_df: pd.DataFrame, epsilon: float = 50.0, min_samples: int = 3) -> dict:
    """Cluster anomalies using DBSCAN based on spatial proximity.
    
    Args:
        anomalies_df: DataFrame with columns: log_dist_ft, oclock_decimal, depth_pct, length_in, width_in
        epsilon: Maximum distance (ft) between anomalies in same cluster
        min_samples: Minimum anomalies to form a cluster
        
    Returns:
        Dict with cluster_id -> {center_dist, member_count, avg_depth, max_depth, total_length, risk_score, members}
    """
    if anomalies_df.empty:
        return {}
    
    # Extract spatial features: distance and circumferential position
    # Convert o'clock to radians for distance calculation (assuming 48" diameter pipe)
    X = []
    indices = []
    for idx, row in anomalies_df.iterrows():
        dist = row.get("log_dist_ft", 0)
        oclock = row.get("oclock_decimal")
        # If we have o'clock, include it in clustering (scaled to ft for comparable units)
        # Approximate: 1 hour on clock = pi*diameter/12 ~ 4 inches ~ 0.33 ft for 48" pipe
        if oclock is not None and not math.isnan(oclock):
            circum_dist = oclock * 0.33  # Rough circumferential distance
            X.append([dist, circum_dist])
        else:
            X.append([dist, 0])
        indices.append(idx)
    
    X = np.array(X)
    
    # DBSCAN clustering
    clustering = DBSCAN(eps=epsilon, min_samples=min_samples).fit(X)
    labels = clustering.labels_
    
    # Group by cluster
    clusters = {}
    for i, label in enumerate(labels):
        if label == -1:
            continue  # Noise point
        
        if label not in clusters:
            clusters[label] = []
        clusters[label].append(indices[i])
    
    # Compute cluster statistics
    result = {}
    for cluster_id, member_indices in clusters.items():
        members = anomalies_df.loc[member_indices]
        
        center_dist = float(members["log_dist_ft"].mean())
        member_count = len(members)
        
        depths = members["depth_pct"].dropna()
        avg_depth = float(depths.mean()) if len(depths) > 0 else 0
        max_depth = float(depths.max()) if len(depths) > 0 else 0
        
        lengths = members["length_in"].dropna()
        total_length = float(lengths.sum()) if len(lengths) > 0 else 0
        
        # Risk score: higher if many anomalies, deep, long total extent
        risk_score = (member_count * 0.3) + (max_depth * 0.01) + (total_length * 0.02)
        risk_score = min(risk_score, 10.0)  # Cap at 10
        
        result[f"cluster_{cluster_id}"] = {
            "center_dist": round(center_dist, 1),
            "span_start": round(float(members["log_dist_ft"].min()), 1),
            "span_end": round(float(members["log_dist_ft"].max()), 1),
            "member_count": member_count,
            "avg_depth_pct": round(avg_depth, 1),
            "max_depth_pct": round(max_depth, 1),
            "total_length_in": round(total_length, 1),
            "risk_score": round(risk_score, 2),
            "member_distances": [round(float(d), 1) for d in members["log_dist_ft"].tolist()[:10]],  # First 10
        }
    
    return result
