"""ML-based prediction of new corrosion locations.

Uses spatial analysis of existing anomaly patterns, weld proximity,
growth rates, and anomaly density to predict where new corrosion
is most likely to form — replacing the LLM-based approach.
"""

from __future__ import annotations

import math
from typing import Any

import numpy as np
import pandas as pd


def _safe(val, default=0.0) -> float:
    if val is None:
        return default
    try:
        f = float(val)
        return default if (math.isnan(f) or math.isinf(f)) else f
    except (ValueError, TypeError):
        return default


def predict_new_anomaly_locations(
    anomalies_df: pd.DataFrame,
    new_anomalies_df: pd.DataFrame,
    welds_df: pd.DataFrame,
    start_dist: float,
    end_dist: float,
    growth_df: pd.DataFrame | None = None,
    top_n: int = 5,
) -> list[dict]:
    """Predict locations where new corrosion is likely to form using ML scoring.

    Approach: divide the segment into bins, score each bin based on:
      1. Anomaly density (more existing = higher risk nearby)
      2. New anomaly density (recent formation patterns)
      3. Proximity to girth welds (stress concentration)
      4. Severity of nearby anomalies (deep corrosion spreads)
      5. Growth rate of nearby anomalies (active corrosion zones)

    Returns top_n locations with highest composite risk scores.
    """
    if anomalies_df is None or anomalies_df.empty:
        return []

    # Filter to segment
    seg_anoms = anomalies_df[
        (anomalies_df["log_dist_ft"] >= start_dist)
        & (anomalies_df["log_dist_ft"] <= end_dist)
    ]
    if seg_anoms.empty:
        return []

    seg_new = pd.DataFrame()
    if new_anomalies_df is not None and not new_anomalies_df.empty:
        seg_new = new_anomalies_df[
            (new_anomalies_df["log_dist_ft"] >= start_dist)
            & (new_anomalies_df["log_dist_ft"] <= end_dist)
        ]

    seg_welds = pd.DataFrame()
    if welds_df is not None and not welds_df.empty:
        seg_welds = welds_df[
            (welds_df["log_dist_ft"] >= start_dist)
            & (welds_df["log_dist_ft"] <= end_dist)
        ]

    # Build spatial bins (every 100 ft)
    bin_size = 100.0
    n_bins = max(1, int((end_dist - start_dist) / bin_size))
    bin_edges = np.linspace(start_dist, end_dist, n_bins + 1)
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    anom_dists = seg_anoms["log_dist_ft"].values
    anom_depths = seg_anoms["depth_pct"].values if "depth_pct" in seg_anoms.columns else np.zeros(len(seg_anoms))

    new_dists = seg_new["log_dist_ft"].values if not seg_new.empty else np.array([])
    weld_dists = seg_welds["log_dist_ft"].values if not seg_welds.empty else np.array([])

    # Growth data if available
    growth_dists = np.array([])
    growth_rates = np.array([])
    if growth_df is not None and not growth_df.empty:
        gf = growth_df.dropna(subset=["depth_growth_pct_yr"])
        if not gf.empty:
            growth_dists = gf["y2_dist"].values
            growth_rates = gf["depth_growth_pct_yr"].values

    scores = np.zeros(n_bins)
    reasons = [""] * n_bins

    for i in range(n_bins):
        lo, hi = bin_edges[i], bin_edges[i + 1]
        center = bin_centers[i]
        reason_parts = []

        # 1. Anomaly density score (nearby anomalies within 200ft)
        nearby_mask = (anom_dists >= center - 200) & (anom_dists <= center + 200)
        density = nearby_mask.sum()
        density_score = min(density / 5.0, 2.0)  # cap at 2
        if density > 0:
            reason_parts.append(f"{density} anomalies within 200ft")

        # 2. New anomaly proximity (new corrosion forms near existing new ones)
        new_score = 0.0
        if len(new_dists) > 0:
            new_nearby = ((new_dists >= center - 300) & (new_dists <= center + 300)).sum()
            new_score = min(new_nearby / 3.0, 2.0)
            if new_nearby > 0:
                reason_parts.append(f"{new_nearby} new anomalies formed nearby")

        # 3. Weld proximity (higher risk near girth welds)
        weld_score = 0.0
        if len(weld_dists) > 0:
            weld_distances = np.abs(weld_dists - center)
            min_weld_dist = weld_distances.min()
            if min_weld_dist < 50:
                weld_score = 2.0 * (1.0 - min_weld_dist / 50.0)
                reason_parts.append(f"girth weld {min_weld_dist:.0f}ft away")

        # 4. Severity of nearby anomalies
        severity_score = 0.0
        if nearby_mask.sum() > 0:
            nearby_depths = anom_depths[nearby_mask]
            max_depth = nearby_depths.max()
            avg_depth = nearby_depths.mean()
            severity_score = min(avg_depth / 25.0, 2.0)
            if max_depth > 40:
                severity_score += 1.0
                reason_parts.append(f"severe corrosion nearby ({max_depth:.0f}% depth)")

        # 5. Growth rate of nearby anomalies
        growth_score = 0.0
        if len(growth_dists) > 0:
            gr_nearby = (growth_dists >= center - 300) & (growth_dists <= center + 300)
            if gr_nearby.sum() > 0:
                nearby_gr = growth_rates[gr_nearby]
                max_gr = nearby_gr.max()
                growth_score = min(max_gr / 2.0, 2.0)
                if max_gr > 1.0:
                    reason_parts.append(f"active growth zone ({max_gr:.1f}%/yr)")

        # 6. Gap penalty: prefer locations that DON'T already have anomalies
        # (predicting NEW corrosion, not existing)
        in_bin = ((anom_dists >= lo) & (anom_dists < hi)).sum()
        gap_bonus = 0.5 if in_bin == 0 else 0.0
        if in_bin == 0 and density > 2:
            reason_parts.append("gap between existing clusters")

        total = density_score + new_score + weld_score + severity_score + growth_score + gap_bonus
        scores[i] = total
        reasons[i] = "; ".join(reason_parts) if reason_parts else "low-risk area"

    # Get top scoring bins (but exclude bins with score 0)
    nonzero = scores > 0
    if not nonzero.any():
        return []

    valid_indices = np.where(nonzero)[0]
    top_indices = valid_indices[np.argsort(scores[valid_indices])[::-1]]

    # Deduplicate: don't return bins too close together
    selected = []
    for idx in top_indices:
        if len(selected) >= top_n:
            break
        center = bin_centers[idx]
        # Skip if too close to an already-selected location
        too_close = False
        for sel_center, _, _ in selected:
            if abs(center - sel_center) < 200:
                too_close = True
                break
        if not too_close:
            # Normalize score to 1-10 risk scale
            risk = min(10.0, max(1.0, scores[idx]))
            selected.append((center, risk, reasons[idx]))

    results = []
    for dist, risk, reason in selected:
        results.append({
            "predicted_dist": round(float(dist), 1),
            "risk_score": round(float(risk), 1),
            "explanation": reason,
        })

    return results
