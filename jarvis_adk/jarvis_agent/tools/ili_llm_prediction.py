"""LLM-based prediction for ILI analysis: growth rates, new anomalies, risk assessment.

Uses the LLM from settings (Featherless.ai API) to predict future corrosion
and assess pipeline risk.
"""

from __future__ import annotations

import json
import re
from typing import Any

import pandas as pd

try:
    import openai
except ImportError:
    openai = None


def call_llm(prompt: str, api_key: str, model: str, base_url: str) -> str:
    """Call LLM via OpenAI-compatible API (Featherless.ai).
    
    Args:
        prompt: Input prompt
        api_key: API key for Featherless.ai
        model: Model name (e.g., "Qwen/Qwen2.5-14B-Instruct")
        base_url: Base URL (e.g., "https://api.featherless.ai/v1")
        
    Returns:
        LLM response text
    """
    if not openai:
        return "Error: openai library not installed. Run: pip install openai"
    
    if not api_key or not model:
        return "Error: API key and model required"
    
    try:
        client = openai.OpenAI(api_key=api_key, base_url=base_url)
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=800,
        )
        return response.choices[0].message.content or ""
    except Exception as e:
        return f"Error calling LLM: {str(e)}"


def predict_growth(
    growth_df: pd.DataFrame,
    pair: str,
    top_n: int,
    api_key: str,
    model: str,
    base_url: str
) -> list[dict]:
    """Predict future growth for top anomalies using LLM.
    
    Args:
        growth_df: Growth dataframe for a run pair (from ds.growth)
        pair: Run pair (e.g., "2015->2022")
        top_n: Number of top growing anomalies to predict
        api_key, model, base_url: LLM API credentials
        
    Returns:
        List of predictions: [{y2_dist, y2_depth_pct, depth_growth_pct_yr, predicted_2027, predicted_2032, explanation}]
    """
    if growth_df.empty:
        return []
    
    # Get top growing anomalies
    top_df = growth_df.dropna(subset=["depth_growth_pct_yr"]).nlargest(top_n, "depth_growth_pct_yr")
    
    results = []
    for _, row in top_df.head(5).iterrows():  # Predict for top 5 to save LLM calls
        y2_dist = row.get("y2_dist", 0)
        y1_depth = row.get("y1_depth_pct", 0)
        y2_depth = row.get("y2_depth_pct", 0)
        depth_growth = row.get("depth_growth_pct_yr", 0)
        years_between = row.get("years_between", 7)
        
        # Build prompt
        prompt = f"""Anomaly at pipeline distance {y2_dist:.1f} ft shows corrosion growth:
- Earlier inspection: {y1_depth:.1f}% depth
- Recent inspection: {y2_depth:.1f}% depth
- Time between inspections: {years_between} years
- Growth rate: {depth_growth:.2f}%/year

Based on this trend, predict the depth percentage in 2027 (5 years from 2022) and 2032 (10 years from 2022).
Consider: accelerating corrosion, environmental factors, typical pipeline aging. 
Assume growth may accelerate as depth increases.

Respond in JSON format:
{{"predicted_2027": <number>, "predicted_2032": <number>, "explanation": "<brief reason>"}}"""
        
        response = call_llm(prompt, api_key, model, base_url)
        
        # Parse JSON from response
        try:
            # Extract JSON block if wrapped in markdown
            json_match = re.search(r'\{[^{}]*"predicted_2027"[^{}]*\}', response, re.DOTALL)
            if json_match:
                pred = json.loads(json_match.group())
                results.append({
                    "y2_dist": round(y2_dist, 1),
                    "y2_depth_pct": round(y2_depth, 1),
                    "depth_growth_pct_yr": round(depth_growth, 2),
                    "predicted_2027": pred.get("predicted_2027"),
                    "predicted_2032": pred.get("predicted_2032"),
                    "explanation": pred.get("explanation", ""),
                })
            else:
                # Fallback: linear extrapolation
                pred_2027 = y2_depth + (depth_growth * 5)
                pred_2032 = y2_depth + (depth_growth * 10)
                results.append({
                    "y2_dist": round(y2_dist, 1),
                    "y2_depth_pct": round(y2_depth, 1),
                    "depth_growth_pct_yr": round(depth_growth, 2),
                    "predicted_2027": round(pred_2027, 1),
                    "predicted_2032": round(pred_2032, 1),
                    "explanation": "Linear extrapolation (LLM response parsing failed)",
                })
        except Exception:
            # Fallback
            pred_2027 = y2_depth + (depth_growth * 5)
            pred_2032 = y2_depth + (depth_growth * 10)
            results.append({
                "y2_dist": round(y2_dist, 1),
                "y2_depth_pct": round(y2_depth, 1),
                "depth_growth_pct_yr": round(depth_growth, 2),
                "predicted_2027": round(pred_2027, 1),
                "predicted_2032": round(pred_2032, 1),
                "explanation": "Linear extrapolation (LLM error)",
            })
    
    return results


def predict_new_anomalies(
    anomalies_df: pd.DataFrame,
    new_anomalies_df: pd.DataFrame,
    welds_df: pd.DataFrame,
    start_dist: float,
    end_dist: float,
    api_key: str,
    model: str,
    base_url: str
) -> list[dict]:
    """Predict locations where new corrosion is likely to form using LLM.
    
    Args:
        anomalies_df: All anomalies in recent run
        new_anomalies_df: New anomalies that appeared in recent run
        welds_df: Girth weld locations
        start_dist, end_dist: Pipeline segment to analyze
        api_key, model, base_url: LLM API credentials
        
    Returns:
        List of predictions: [{predicted_dist, risk_score, explanation}]
    """
    # Filter to segment
    segment_anoms = anomalies_df[(anomalies_df["log_dist_ft"] >= start_dist) & (anomalies_df["log_dist_ft"] <= end_dist)]
    segment_new = new_anomalies_df[(new_anomalies_df["log_dist_ft"] >= start_dist) & (new_anomalies_df["log_dist_ft"] <= end_dist)]
    segment_welds = welds_df[(welds_df["log_dist_ft"] >= start_dist) & (welds_df["log_dist_ft"] <= end_dist)]
    
    # Build summary
    new_locs = segment_new["log_dist_ft"].tolist()[:10]
    weld_locs = segment_welds["log_dist_ft"].tolist()[:10]
    severe = segment_anoms[segment_anoms["depth_pct"] > 40]
    severe_locs = severe["log_dist_ft"].tolist()[:5]
    
    prompt = f"""Pipeline segment from {start_dist:.0f}-{end_dist:.0f} ft analysis:
- Anomaly density: {len(segment_anoms)} anomalies in this segment
- New anomalies formed (recent inspection): {len(segment_new)} at distances: {', '.join(f'{d:.0f} ft' for d in new_locs)}
- Girth welds at: {', '.join(f'{d:.0f} ft' for d in weld_locs)}
- Existing severe anomalies (>40% depth): {len(severe)} at: {', '.join(f'{d:.0f} ft' for d in severe_locs)}

Predict 5 locations (in ft) where new corrosion is most likely to form by next inspection. Consider:
- Proximity to existing defects (corrosion spreads axially)
- Proximity to girth welds (stress concentration)
- Historical pattern of new anomaly formation

Respond in JSON format:
{{"predictions": [{{"distance": <number>, "risk_score": <1-10>, "reason": "<brief>"}}]}}"""
    
    response = call_llm(prompt, api_key, model, base_url)
    
    # Parse JSON - handle nested structure and markdown code blocks
    def _extract_json(text: str) -> dict | None:
        # Try markdown code block first
        code_match = re.search(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', text)
        if code_match:
            try:
                return json.loads(code_match.group(1))
            except json.JSONDecodeError:
                pass
        # Find { before "predictions" and extract balanced braces
        idx = text.find('"predictions"')
        if idx < 0:
            return None
        start = text.rfind('{', 0, idx + 1)
        if start < 0:
            return None
        depth = 0
        for i in range(start, len(text)):
            c = text[i]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(text[start:i + 1])
                    except json.JSONDecodeError:
                        return None
        return None

    try:
        data = _extract_json(response)
        if data:
            preds = data.get("predictions", [])
            results = []
            for p in preds[:5]:
                dist = p.get("distance")
                if dist is not None:
                    results.append({
                        "predicted_dist": float(dist) if not isinstance(dist, (int, float)) else dist,
                        "risk_score": p.get("risk_score", 5),
                        "explanation": p.get("reason", "") or p.get("explanation", ""),
                    })
            return results
    except Exception:
        pass

    return []


def risk_assessment(
    summary: dict,
    growth_stats: dict,
    top_growing: list,
    api_key: str,
    model: str,
    base_url: str
) -> dict:
    """Generate pipeline risk assessment and action items using LLM.
    
    Args:
        summary: Pipeline summary (from ds.get_summary_stats())
        growth_stats: Growth statistics (from ds.calculate_growth())
        top_growing: Top growing anomalies
        api_key, model, base_url: LLM API credentials
        
    Returns:
        {overall_risk: str, risk_level: str, action_items: [str]}
    """
    # Extract key stats
    runs = summary.get("runs_loaded", [])
    latest_run = max(runs) if runs else 2022
    run_stats = summary.get(f"run_{latest_run}", {})
    total_anoms = run_stats.get("metal_loss", 0)
    max_depth = run_stats.get("max_depth_pct", 0)
    
    # Growth stats
    critical_count = 0
    high_count = 0
    for pair_stats in growth_stats.values():
        critical_count += pair_stats.get("critical_count", 0)
        high_count += pair_stats.get("high_count", 0)
    
    # Top growing
    top_3 = top_growing[:3] if top_growing else []
    top_desc = []
    for item in top_3:
        dist = item.get("y2_dist", 0)
        depth = item.get("y2_depth_pct", 0)
        growth = item.get("depth_growth_pct_yr", 0)
        top_desc.append(f"Anomaly at {dist:.0f} ft: {depth:.1f}% depth, growing {growth:.2f}%/yr")
    
    prompt = f"""Pipeline Integrity Assessment:

Inspection Data ({latest_run}):
- Total metal-loss anomalies: {total_anoms}
- Maximum depth: {max_depth:.1f}%
- Critical growth rate anomalies (>3%/yr): {critical_count}
- High growth rate anomalies (>2%/yr): {high_count}

Top Growing Anomalies:
{chr(10).join(f'- {d}' for d in top_desc)}

Provide a concise risk assessment (2-3 sentences) and top 5 action items for integrity management.
Consider: inspection frequency, dig priorities, failure risk.

Respond in JSON format:
{{"overall_risk": "<2-3 sentence assessment>", "risk_level": "<Low|Medium|High|Critical>", "action_items": ["<action 1>", "<action 2>", ...]}}"""
    
    response = call_llm(prompt, api_key, model, base_url)
    
    # Parse JSON
    try:
        json_match = re.search(r'\{[^{}]*"overall_risk"[^{}]*\}', response, re.DOTALL | re.IGNORECASE)
        if json_match:
            data = json.loads(json_match.group())
            return {
                "overall_risk": data.get("overall_risk", ""),
                "risk_level": data.get("risk_level", "Medium"),
                "action_items": data.get("action_items", [])[:5],
            }
    except Exception:
        pass
    
    # Fallback
    return {
        "overall_risk": f"Pipeline has {total_anoms} metal-loss anomalies with {critical_count} showing critical growth rates. Maximum depth is {max_depth:.1f}%. Requires prioritized integrity management.",
        "risk_level": "High" if critical_count > 10 else "Medium",
        "action_items": [
            f"Prioritize excavation of {critical_count} anomalies with critical growth rates",
            f"Re-inspect high-growth segments within 3-5 years",
            "Monitor anomalies exceeding 40% depth quarterly",
            "Implement corrosion mitigation in high-density clusters",
            "Review and update integrity management plan",
        ],
    }
