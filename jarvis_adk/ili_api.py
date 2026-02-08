"""Lightweight REST API for ILI dashboard data.

Run alongside the ADK server:
    uvicorn ili_api:app --port 8001

The Flutter ILI dashboard screen calls these endpoints directly
for fast, structured data without going through the LLM agent loop.
"""

from __future__ import annotations

import json
import math
import os
from pathlib import Path
import pandas as pd

def _log(msg: str):
    """Log to stdout so it appears in uvicorn terminal."""
    print(f"[ILI] {msg}", flush=True)

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from jarvis_agent.tools.ili_processing import get_dataset, reset_dataset
from jarvis_agent.tools.ili_clustering import cluster_anomalies
from jarvis_agent.tools.ili_llm_prediction import predict_growth, predict_new_anomalies, risk_assessment
from jarvis_agent.tools.ili_ml_new_anomaly import predict_new_anomaly_locations

app = FastAPI(title="JARVIS ILI API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_DEFAULT_FILE = str(Path(__file__).resolve().parent.parent / "ILIDataV2.xlsx")


def _clean(obj):
    """Recursively replace NaN/Inf with None for JSON serialization."""
    if isinstance(obj, dict):
        return {k: _clean(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_clean(v) for v in obj]
    if isinstance(obj, float) and (math.isnan(obj) or math.isinf(obj)):
        return None
    return obj


@app.get("/ili/load")
def load_data(file_path: str = ""):
    """Load ILI data from Excel file."""
    reset_dataset()
    ds = get_dataset()
    path = file_path.strip() if file_path.strip() else _DEFAULT_FILE
    result = ds.load(path)
    return _clean(result)


@app.get("/ili/summary")
def summary():
    """Get pipeline summary statistics."""
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    return _clean(ds.get_summary_stats())


@app.get("/ili/align")
def align():
    """Run weld alignment and return quality metrics."""
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    result = ds.align_welds()
    return _clean(result)


@app.get("/ili/alignment-data")
def alignment_data():
    """Get alignment visualization data (weld matches + correction curves)."""
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    if not ds.correction_funcs:
        ds.align_welds()
    return _clean(ds.get_alignment_data())


@app.get("/ili/match")
def match():
    """Run anomaly matching and return statistics."""
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    if not ds.correction_funcs:
        ds.align_welds()
    result = ds.match_anomalies()
    return _clean(result)


@app.get("/ili/growth")
def growth(top_n: int = Query(20, ge=1, le=500)):
    """Calculate growth rates and return top fastest-growing anomalies."""
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    if not ds.correction_funcs:
        ds.align_welds()
    if not ds.matches:
        ds.match_anomalies()
    stats = ds.calculate_growth()
    top = ds.get_top_growth(top_n=top_n)
    return _clean({"statistics": stats, "top_growing": top})


@app.get("/ili/matches/{pair}")
def match_details(
    pair: str,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """Get detailed match results for a specific run pair (e.g. '2015->2022')."""
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    if not ds.correction_funcs:
        ds.align_welds()
    if not ds.matches:
        ds.match_anomalies()
    if not ds.growth:
        ds.calculate_growth()
    data = ds.get_match_details(pair, limit=limit, offset=offset)
    return _clean(data)


@app.get("/ili/profile/{year}")
def profile(year: int):
    """Get pipeline profile data (distance vs depth) for a specific year."""
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    data = ds.get_profile_data(year)
    return _clean(data)


@app.get("/ili/run-all")
def run_all():
    """Run the full pipeline: load, align, match, growth. Returns everything."""
    _log("Pipeline started")
    reset_dataset()
    ds = get_dataset()

    _log("Step 1/5: Loading data...")
    load_result = ds.load(_DEFAULT_FILE)
    _log(f"Step 1/5: Load complete ({list(load_result.get('runs', {}).keys())})")

    _log("Step 2/5: Aligning welds...")
    align_result = ds.align_welds()
    align_pairs = align_result.get("weld_alignment", [])
    _log(f"Step 2/5: Align complete ({len(align_pairs)} pairs)")

    _log("Step 3/5: Matching anomalies...")
    match_result = ds.match_anomalies()
    _log(f"Step 3/5: Match complete ({len(match_result)} pairs)")

    _log("Step 4/5: Calculating growth...")
    growth_result = ds.calculate_growth()
    _log("Step 4/5: Growth complete")

    _log("Step 5/5: Getting top growing anomalies...")
    top_growing = ds.get_top_growth(top_n=30)
    _log(f"Step 5/5: Pipeline complete ({len(top_growing)} top growing)")

    return _clean({
        "load": load_result,
        "alignment": align_result,
        "matching": match_result,
        "growth": growth_result,
        "top_growing": top_growing,
        "summary": ds.get_summary_stats(),
    })


# ---------------------------------------------------------------------------
# AI/ML Endpoints
# ---------------------------------------------------------------------------

@app.get("/ili/clusters")
def clusters(year: int = Query(2022), epsilon: float = Query(50.0), min_samples: int = Query(3)):
    """Identify spatial clusters of anomalies using DBSCAN.
    
    Args:
        year: Inspection year to cluster (2007, 2015, or 2022)
        epsilon: Maximum distance (ft) between anomalies in same cluster
        min_samples: Minimum anomalies to form a cluster
        
    Returns:
        Dict of clusters with stats: {cluster_0: {center_dist, member_count, avg_depth, ...}}
    """
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    
    if year not in ds.anomalies:
        return {"error": f"No data for year {year}"}
    
    anoms = ds.anomalies[year]
    result = cluster_anomalies(anoms, epsilon=epsilon, min_samples=min_samples)
    return _clean(result)


@app.get("/ili/predict-growth")
def predict_growth_endpoint(
    pair: str = Query("2015->2022"),
    top_n: int = Query(5, ge=1, le=20),
    api_key: str = Query(""),
    model: str = Query("Qwen/Qwen2.5-14B-Instruct"),
    base_url: str = Query("https://api.featherless.ai/v1"),
):
    """Predict future growth for top anomalies using LLM.
    
    Args:
        pair: Run pair (e.g., "2015->2022")
        top_n: Number of top growing anomalies to predict (max 20)
        api_key: Featherless.ai API key
        model: LLM model name
        base_url: Featherless.ai base URL
        
    Returns:
        List of predictions with predicted_2027, predicted_2032, explanation
    """
    parts = pair.split("->")
    if len(parts) != 2:
        return {"error": f"Invalid pair format: {pair}"}

    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    y1, y2 = int(parts[0]), int(parts[1])
    if y1 not in ds.references or y2 not in ds.references:
        reset_dataset()
        ds = get_dataset()
        ds.load(_DEFAULT_FILE)
    if not ds.correction_funcs:
        ds.align_welds()
    if not ds.matches:
        ds.match_anomalies()
    if not ds.growth:
        ds.calculate_growth()
    
    key = (y1, y2)
    if key not in ds.growth:
        return {"error": f"No growth data for {pair}"}
    
    growth_df = ds.growth[key]
    predictions = predict_growth(growth_df, pair, top_n, api_key, model, base_url)
    return _clean(predictions)


@app.get("/ili/predict-new-anomalies")
def predict_new_anomalies_endpoint(
    year: int = Query(2022),
    start_dist: float = Query(0),
    end_dist: float = Query(5000),
    top_n: int = Query(5),
):
    """Predict locations where new corrosion is likely to form using ML scoring.

    Args:
        year: Recent inspection year
        start_dist, end_dist: Pipeline segment to analyze (ft)
        top_n: Number of top predictions to return

    Returns:
        List of predictions: [{predicted_dist, risk_score, explanation}]
    """
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    if not ds.matches:
        ds.align_welds()
        ds.match_anomalies()
    if not ds.growth:
        ds.calculate_growth()

    if year not in ds.anomalies:
        return {"error": f"No data for year {year}"}

    # Get new anomalies (unmatched in later run)
    new_anoms = pd.DataFrame()
    for (y1, y2), matches_df in ds.matches.items():
        if y2 == year:
            ml2 = ds.anomalies[y2]
            used = set(matches_df["y2_idx"].tolist())
            new_anoms = ml2[~ml2.index.isin(used)]
            break

    # Get growth data for the most recent pair
    growth_df = None
    for (y1, y2), gdf in ds.growth.items():
        if y2 == year:
            growth_df = gdf
            break

    anomalies = ds.anomalies[year]
    refs = ds.references.get(year, pd.DataFrame())
    welds = refs[refs["event"].str.lower().str.contains("weld")] if len(refs) > 0 else pd.DataFrame()

    predictions = predict_new_anomaly_locations(
        anomalies, new_anoms, welds,
        start_dist, end_dist,
        growth_df=growth_df,
        top_n=top_n,
    )
    return _clean(predictions)


@app.get("/ili/risk-assessment")
def risk_assessment_endpoint(
    api_key: str = Query(""),
    model: str = Query("Qwen/Qwen2.5-14B-Instruct"),
    base_url: str = Query("https://api.featherless.ai/v1"),
):
    """Generate pipeline risk assessment and action items using LLM.
    
    Args:
        api_key: Featherless.ai API key
        model: LLM model name
        base_url: Featherless.ai base URL
        
    Returns:
        {overall_risk: str, risk_level: str, action_items: [str]}
    """
    ds = get_dataset()
    if not ds.runs:
        ds.load(_DEFAULT_FILE)
    if not ds.growth:
        if not ds.references or 2022 not in ds.references:
            reset_dataset()
            ds = get_dataset()
            ds.load(_DEFAULT_FILE)
        ds.align_welds()
        ds.match_anomalies()
        ds.calculate_growth()

    summary = ds.get_summary_stats()
    growth_stats = {}
    for (y1, y2), growth_df in ds.growth.items():
        if not growth_df.empty:
            valid_depth = growth_df["depth_growth_pct_yr"].dropna()
            growth_stats[f"{y1}->{y2}"] = {
                "critical_count": int((growth_df["severity"] == "critical").sum()),
                "high_count": int((growth_df["severity"] == "high").sum()),
                "avg_growth": float(valid_depth.mean()) if len(valid_depth) > 0 else 0,
            }
    
    top_growing = ds.get_top_growth(top_n=10)
    result = risk_assessment(summary, growth_stats, top_growing, api_key, model, base_url)
    return _clean(result)
