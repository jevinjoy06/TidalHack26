"""ADK tool wrappers for ILI data alignment.

These functions are registered as tools with the ADK agent so the LLM
can invoke them via function-calling.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from .ili_processing import get_dataset, reset_dataset

# Default path: ILIDataV2.xlsx at repo root
_DEFAULT_FILE = str(Path(__file__).resolve().parent.parent.parent.parent / "ILIDataV2.xlsx")


def ili_load_data(file_path: str = "") -> str:
    """Load ILI inspection data from an Excel file.

    Reads the ILI Excel workbook (Summary, 2007, 2015, 2022 sheets),
    normalises column names, and separates reference points from anomalies.

    Args:
        file_path: Path to the ILI Excel file. Leave empty to use the default ILIDataV2.xlsx.

    Returns:
        JSON summary with row counts, anomaly counts, and distance ranges per run.
    """
    reset_dataset()
    ds = get_dataset()
    path = file_path.strip() if file_path.strip() else _DEFAULT_FILE
    result = ds.load(path)
    return json.dumps(result, indent=2, default=str)


def ili_align_runs() -> str:
    """Align ILI inspection runs by matching girth welds.

    Matches girth welds across 2007, 2015, and 2022 runs by joint number,
    then builds piecewise linear correction functions to compensate for
    odometer drift between runs.

    Returns:
        JSON with alignment quality metrics (matched welds, offsets, etc.).
    """
    ds = get_dataset()
    if not ds.runs:
        return json.dumps({"error": "No data loaded. Call ili_load_data first."})
    result = ds.align_welds()
    return json.dumps(result, indent=2, default=str)


def ili_match_anomalies() -> str:
    """Match metal-loss anomalies across ILI runs.

    Uses corrected distances, clock positions, and depth similarity to
    pair anomalies from earlier runs to later runs. Flags new anomalies,
    missing anomalies, and uncertain matches.

    Returns:
        JSON with match counts, confidence breakdown, and new/missing counts per run pair.
    """
    ds = get_dataset()
    if not ds.runs:
        return json.dumps({"error": "No data loaded. Call ili_load_data first."})
    if not ds.correction_funcs:
        ds.align_welds()
    result = ds.match_anomalies()
    return json.dumps(result, indent=2, default=str)


def ili_growth_rates(sort_by: str = "depth", top_n: int = 20) -> str:
    """Calculate and return corrosion growth rates for matched anomalies.

    Computes depth (%/year), length (in/year), and width (in/year) growth
    rates for all matched anomaly pairs. Flags severity levels:
    critical (>3%/yr), high (>2%/yr), moderate (>1%/yr), normal.

    Args:
        sort_by: Sort results by "depth", "length", or "width" growth. Default "depth".
        top_n: Number of top results to return. Default 20.

    Returns:
        JSON with growth statistics and top fastest-growing anomalies.
    """
    ds = get_dataset()
    if not ds.matches:
        return json.dumps({"error": "No matches found. Call ili_match_anomalies first."})

    stats = ds.calculate_growth()
    top = ds.get_top_growth(top_n=top_n)

    # Clean NaN for JSON
    clean_top = []
    for item in top:
        clean = {}
        for k, v in item.items():
            if isinstance(v, float) and (v != v):  # NaN check
                clean[k] = None
            else:
                clean[k] = v
        clean_top.append(clean)

    return json.dumps({
        "statistics": stats,
        "top_growing": clean_top,
    }, indent=2, default=str)


def ili_query(query: str) -> str:
    """Query ILI alignment results with natural-language-style filters.

    Supported query patterns:
    - "summary" — overall pipeline stats
    - "top growth" or "fastest growing" — top growing defects
    - "new in 2022" — anomalies only in 2022 (not matched to earlier run)
    - "joint 400 to 600" — anomalies in joint range
    - "depth > 40" — anomalies with depth above threshold
    - "critical" / "high" / "moderate" — by severity level
    - "profile 2022" — depth-vs-distance data for charting

    Args:
        query: Natural language query string.

    Returns:
        JSON results matching the query.
    """
    ds = get_dataset()
    q = query.strip().lower()

    if "summary" in q or "stats" in q or "overview" in q:
        return json.dumps(ds.get_summary_stats(), indent=2, default=str)

    if "top" in q or "fastest" in q or "worst" in q:
        n = 20
        for word in q.split():
            try:
                n = int(word)
                break
            except ValueError:
                pass
        top = ds.get_top_growth(top_n=n)
        clean = []
        for item in top:
            r = {}
            for k, v in item.items():
                r[k] = None if isinstance(v, float) and v != v else v
            clean.append(r)
        return json.dumps(clean, indent=2, default=str)

    if "profile" in q:
        for year in [2022, 2015, 2007]:
            if str(year) in q:
                data = ds.get_profile_data(year)
                return json.dumps(data[:200], indent=2, default=str)
        data = ds.get_profile_data(2022)
        return json.dumps(data[:200], indent=2, default=str)

    if "alignment" in q or "weld" in q or "correction" in q:
        return json.dumps(ds.get_alignment_data(), indent=2, default=str)

    # Build filters dict from query
    filters: dict = {"limit": 50}

    if "new" in q:
        for year in [2022, 2015]:
            if str(year) in q:
                filters["year"] = year
                break

    for sev in ["critical", "high", "moderate", "normal"]:
        if sev in q:
            filters["severity"] = sev
            break

    # Parse "joint X to Y"
    import re
    joint_match = re.search(r"joint\s*(\d+)\s*(?:to|-)\s*(\d+)", q)
    if joint_match:
        filters["joint_min"] = int(joint_match.group(1))
        filters["joint_max"] = int(joint_match.group(2))

    depth_match = re.search(r"depth\s*[>]\s*(\d+)", q)
    if depth_match:
        filters["min_depth"] = float(depth_match.group(1))

    # Try growth data first, fall back to raw anomalies
    if "pair" not in filters and ds.growth:
        filters["pair"] = "2015->2022"

    result = ds.query_anomalies(filters)
    clean = []
    for item in result:
        r = {}
        for k, v in item.items():
            r[k] = None if isinstance(v, float) and v != v else v
        clean.append(r)
    return json.dumps(clean, indent=2, default=str)
